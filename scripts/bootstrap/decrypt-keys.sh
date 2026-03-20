#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for sops-nix on a new machine
# Decrypts the master key and sets up sops for initial configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MASTER_KEY_ENC="$REPO_ROOT/secrets/id_mothership.age"
SOPS_AGE_DIR="$HOME/.config/sops/age"
SOPS_KEY_FILE="$SOPS_AGE_DIR/keys.txt"

echo "=== sops-nix Bootstrap Script ==="
echo ""

# Step 1: Decrypt master key for sops
echo "Step 1: Decrypting master key for sops..."
mkdir -p "$SOPS_AGE_DIR"
chmod 700 "$SOPS_AGE_DIR"

age --decrypt -o "$SOPS_KEY_FILE" "$MASTER_KEY_ENC"
chmod 600 "$SOPS_KEY_FILE"
echo "Master key decrypted to $SOPS_KEY_FILE"
echo ""

# Step 2: Show this machine's age key (derived from SSH host key)
echo "Step 2: This machine's age public key (from SSH host key):"
if command -v ssh-to-age &>/dev/null; then
    HOST_AGE_KEY=$(cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age)
    echo "  $HOST_AGE_KEY"
else
    echo "  Run: nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'"
fi
echo ""

# Step 3: Instructions
echo "Step 3: Next steps:"
echo ""
echo "  1. Add this machine's key to .sops.yaml if not already present:"
echo "     vim $REPO_ROOT/.sops.yaml"
echo ""
echo "  2. Re-encrypt secrets for this machine:"
echo "     cd $REPO_ROOT && sops updatekeys secrets/secrets.yaml"
echo ""
echo "  3. Build and switch:"
echo "     sudo nixos-rebuild switch --flake $REPO_ROOT#<hostname>"
echo ""
echo "  4. After successful boot, clean up the master key:"
echo "     shred -u $SOPS_KEY_FILE"
echo ""
echo "Note: After first boot, secrets decrypt automatically via SSH host key."
echo "      The master key is only needed for bootstrapping or editing secrets."
