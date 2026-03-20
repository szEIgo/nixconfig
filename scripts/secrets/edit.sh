#!/usr/bin/env bash
set -euo pipefail

# Edit encrypted secrets (requires master key)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOPS_KEY_FILE="$HOME/.config/sops/age/keys.txt"

if [[ ! -f "$SOPS_KEY_FILE" ]]; then
    echo "Master key not found. Decrypting..."
    age --decrypt -o "$SOPS_KEY_FILE" "$REPO_ROOT/secrets/id_mothership.age"
    chmod 600 "$SOPS_KEY_FILE"
fi

sops "$REPO_ROOT/secrets/secrets.yaml"
