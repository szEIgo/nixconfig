#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Add SSH keys for a new host
#
# Connects to a host, generates an SSH key pair, stores the private key in
# SOPS, adds the public key to authorized_keys, and creates a secrets nix
# file for the host. After running, add SOPS to the host's flake entry and
# rebuild.
#
# Usage: add-host-keys.sh <hostname> <ip>
# Example: add-host-keys.sh nuc 192.168.2.102
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
    echo "Example: $0 nuc 192.168.2.102"
    exit 1
fi

SSH_USER="${SSH_USER:-joni}"
SOPS_FILE="$REPO_ROOT/secrets/secrets.yaml"
SOPS_YAML="$REPO_ROOT/.sops.yaml"
AUTH_KEYS="$REPO_ROOT/remote/authorized_keys"
SECRETS_NIX="$REPO_ROOT/secrets/${HOST}.nix"

echo -e "${BLUE}=== Adding SSH keys for ${HOST} (${IP}) ===${NC}"
echo ""

# ---- Step 1: Get age key ----
echo -e "${BLUE}[1/5] Getting age key from ${HOST}...${NC}"
AGE_KEY=$(ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 "${SSH_USER}@${IP}" \
    'nix-shell -p ssh-to-age --run "cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age"' 2>/dev/null)

if [[ -z "$AGE_KEY" ]]; then
    echo -e "${RED}Failed to get age key from ${HOST}${NC}"
    exit 1
fi
echo -e "  Age key: ${GREEN}${AGE_KEY}${NC}"

# ---- Step 2: Generate SSH key pair ----
echo -e "${BLUE}[2/5] Generating SSH key pair on ${HOST}...${NC}"
KEY_OUTPUT=$(ssh "${SSH_USER}@${IP}" "
    rm -f /tmp/id_ed25519_${HOST} /tmp/id_ed25519_${HOST}.pub
    ssh-keygen -t ed25519 -N '' -f /tmp/id_ed25519_${HOST} -C '${SSH_USER}@${HOST}' 2>/dev/null
    echo '---PUBLIC---'
    cat /tmp/id_ed25519_${HOST}.pub
    echo '---PRIVATE---'
    cat /tmp/id_ed25519_${HOST}
")

PUB_KEY=$(echo "$KEY_OUTPUT" | sed -n '/---PUBLIC---/,/---PRIVATE---/p' | grep -v '^---')
PRIV_KEY=$(echo "$KEY_OUTPUT" | sed -n '/---PRIVATE---/,$ p' | grep -v '^---')

echo -e "  Public key: ${GREEN}${PUB_KEY}${NC}"

# ---- Step 3: Add age key to .sops.yaml ----
echo -e "${BLUE}[3/5] Adding age key to .sops.yaml...${NC}"
if grep -q "&${HOST}" "$SOPS_YAML"; then
    echo -e "  ${YELLOW}Host ${HOST} already in .sops.yaml, skipping${NC}"
else
    # Add host key anchor after the last machine key
    sed -i "/^creation_rules:/i\\  - \&${HOST} ${AGE_KEY}" "$SOPS_YAML"

    # Add host to the age key list in creation_rules
    sed -i "/key_groups:/,/^$/{/- \*/a\\          - *${HOST}
    }" "$SOPS_YAML"

    echo -e "  ${GREEN}Added &${HOST} to .sops.yaml${NC}"
fi

# ---- Step 4: Add keys to secrets and authorized_keys ----
echo -e "${BLUE}[4/5] Adding keys to SOPS and authorized_keys...${NC}"

# Add public key to authorized_keys (if not already there)
if grep -q "${SSH_USER}@${HOST}" "$AUTH_KEYS"; then
    echo -e "  ${YELLOW}Public key already in authorized_keys, skipping${NC}"
else
    echo "$PUB_KEY" >> "$AUTH_KEYS"
    echo -e "  ${GREEN}Added public key to authorized_keys${NC}"
fi

# Re-encrypt with new age key
sops updatekeys "$SOPS_FILE" --yes 2>/dev/null

# Add private key to SOPS
ESCAPED_KEY=$(echo "$PRIV_KEY" | awk '{printf "%s\\n", $0}')
sops --set "[\"ssh_${HOST}\"] \"${ESCAPED_KEY}\"" "$SOPS_FILE"
echo -e "  ${GREEN}Added private key to SOPS secrets${NC}"

# ---- Step 5: Create secrets nix file ----
echo -e "${BLUE}[5/5] Creating secrets/${HOST}.nix...${NC}"
if [[ -f "$SECRETS_NIX" ]]; then
    echo -e "  ${YELLOW}${SECRETS_NIX} already exists, skipping${NC}"
else
    cat > "$SECRETS_NIX" << NIXEOF
{ config, pkgs, lib, ... }:

let
  sshDest = "/home/joni/.ssh";
in {
  sops = {
    defaultSopsFile = ./secrets.yaml;

    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };

    secrets = {
      ssh_${HOST} = {
        path = "\${sshDest}/id_ed25519";
        owner = "joni";
        group = "joni";
        mode = "0600";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d \${sshDest} 0700 joni joni -"
  ];
}
NIXEOF
    echo -e "  ${GREEN}Created secrets/${HOST}.nix${NC}"
fi

# ---- Cleanup temp key on remote host ----
ssh "${SSH_USER}@${IP}" "rm -f /tmp/id_ed25519_${HOST} /tmp/id_ed25519_${HOST}.pub" 2>/dev/null || true

# ---- Done ----
echo ""
echo -e "${GREEN}=== Done! ===${NC}"
echo ""
echo "Remaining manual steps:"
echo ""
echo "  1. Add SOPS to the host's flake.nix entry:"
echo ""
echo -e "     ${YELLOW}sops-nix.nixosModules.sops${NC}"
echo -e "     ${YELLOW}./secrets/${HOST}.nix${NC}"
echo ""
echo "  2. Push and rebuild:"
echo ""
echo -e "     ${YELLOW}git add -A && git commit -m 'Add SSH keys for ${HOST}'${NC}"
echo -e "     ${YELLOW}make switch HOST=${HOST}${NC}"
echo ""
echo "  3. Rebuild all other hosts to update authorized_keys"
