#!/usr/bin/env bash
set -euo pipefail

# Securely delete the temporary master key after successful bootstrap

SOPS_KEY_FILE="$HOME/.config/sops/age/keys.txt"

if [[ -f "$SOPS_KEY_FILE" ]]; then
    shred -u "$SOPS_KEY_FILE"
    echo "Master key securely deleted: $SOPS_KEY_FILE"
else
    echo "No master key found at $SOPS_KEY_FILE"
fi
