#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Deploy a k3s worker node via nixos-anywhere
#
# Requires: the target is booted from the worker ISO (or any NixOS live USB)
#
# What this script does:
#   1. Pre-generates an SSH host key for the node
#   2. Derives the age key and adds it to .sops.yaml
#   3. Re-encrypts secrets so the node can decrypt them (k3s token, etc.)
#   4. Runs nixos-anywhere to partition, install, and configure the node
#   5. Cleans up temporary files
#
# Usage: deploy-worker.sh <hostname> <ip>
# Example: deploy-worker.sh carrier-tc1 192.168.2.192
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

HOST="${1:-}"
IP="${2:-}"

if [[ -z "$HOST" || -z "$IP" ]]; then
    echo "Usage: $0 <hostname> <ip>"
    echo "Example: $0 carrier-tc1 192.168.2.192"
    exit 1
fi

SOPS_YAML="$REPO_ROOT/.sops.yaml"
SOPS_FILE="$REPO_ROOT/secrets/secrets.yaml"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo -e "${BLUE}=== Deploying worker node: ${HOST} (${IP}) ===${NC}"
echo ""

# ---- Step 1: Generate SSH host key ----
echo -e "${BLUE}[1/4] Generating SSH host key for ${HOST}...${NC}"
ssh-keygen -t ed25519 -N "" -f "$TEMP_DIR/ssh_host_ed25519_key" -C "root@${HOST}" >/dev/null 2>&1

# Derive age key from the host public key
AGE_KEY=$(nix-shell -p ssh-to-age --run "cat $TEMP_DIR/ssh_host_ed25519_key.pub | ssh-to-age")
echo -e "  Age key: ${GREEN}${AGE_KEY}${NC}"

# ---- Step 2: Add age key to .sops.yaml ----
echo -e "${BLUE}[2/4] Adding age key to .sops.yaml...${NC}"
if grep -q "&${HOST}" "$SOPS_YAML"; then
    echo -e "  ${YELLOW}Host ${HOST} already in .sops.yaml, updating...${NC}"
    sed -i "s|^\(  - &${HOST}\).*|\1 ${AGE_KEY}|" "$SOPS_YAML"
else
    # Add host key anchor before creation_rules
    sed -i "/^creation_rules:/i\\  - \&${HOST} ${AGE_KEY}" "$SOPS_YAML"
    # Add host reference to the key_groups list (before the closing of the age list)
    if ! grep -q "\*${HOST}" "$SOPS_YAML"; then
        # Find the last "- *" entry in key_groups and append after it
        LAST_REF=$(grep -n '          - \*' "$SOPS_YAML" | tail -1 | cut -d: -f1)
        sed -i "${LAST_REF}a\\          - *${HOST}" "$SOPS_YAML"
    fi
    echo -e "  ${GREEN}Added &${HOST} to .sops.yaml${NC}"
fi

# ---- Step 3: Re-encrypt secrets with the new key ----
echo -e "${BLUE}[3/4] Re-encrypting secrets for ${HOST}...${NC}"
sops updatekeys "$SOPS_FILE" --yes 2>/dev/null
echo -e "  ${GREEN}Secrets re-encrypted${NC}"

# ---- Step 4: Run nixos-anywhere ----
echo -e "${BLUE}[4/4] Installing NixOS on ${HOST} via nixos-anywhere...${NC}"
echo ""

# Prepare extra-files: SSH host keys so sops can decrypt on first boot
mkdir -p "$TEMP_DIR/extra/etc/ssh"
cp "$TEMP_DIR/ssh_host_ed25519_key" "$TEMP_DIR/extra/etc/ssh/ssh_host_ed25519_key"
cp "$TEMP_DIR/ssh_host_ed25519_key.pub" "$TEMP_DIR/extra/etc/ssh/ssh_host_ed25519_key.pub"
chmod 600 "$TEMP_DIR/extra/etc/ssh/ssh_host_ed25519_key"

nix run github:nix-community/nixos-anywhere -- \
    --flake "$REPO_ROOT#${HOST}" \
    --extra-files "$TEMP_DIR/extra" \
    root@"${IP}"

echo ""
echo -e "${GREEN}=== ${HOST} deployed successfully! ===${NC}"
echo ""
echo "The node will reboot into a fully configured k3s worker with:"
echo "  - SSH key auth (your authorized_keys)"
echo "  - k3s agent (token deployed via sops)"
echo "  - zsh + powerlevel10k + home-manager"
echo "  - GRUB bootloader on /dev/sda"
