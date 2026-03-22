#!/usr/bin/env bash
set -euo pipefail

# Show which secrets are stored and which hosts can decrypt them

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Secrets ===${NC}"
echo ""

# List secret keys from sops
echo -e "${YELLOW}Encrypted keys in secrets.yaml:${NC}"
sops --output-type json -d "$REPO_ROOT/secrets/secrets.yaml" 2>/dev/null \
    | jq -r 'keys[]' \
    | while read -r key; do
        echo "  - $key"
    done 2>/dev/null || echo "  (cannot decrypt — need master key: make bootstrap)"

echo ""
echo -e "${YELLOW}Host age keys (.sops.yaml):${NC}"
grep '&' "$REPO_ROOT/.sops.yaml" | grep -v '#' | while read -r line; do
    name=$(echo "$line" | grep -oP '&\K\w+')
    key=$(echo "$line" | grep -oP 'age\S+')
    echo -e "  ${GREEN}${name}${NC}: ${key}"
done

echo ""
echo -e "${YELLOW}Per-host secret configs:${NC}"
for f in "$REPO_ROOT"/secrets/*.nix; do
    [[ "$(basename "$f")" == "secrets.nix" ]] && continue
    host=$(basename "$f" .nix)
    secrets=$(grep -oP "ssh_\w+" "$f" | tr '\n' ', ' | sed 's/,$//')
    echo -e "  ${GREEN}${host}${NC}: ${secrets}"
done

echo ""
echo -e "${YELLOW}Authorized public keys:${NC}"
while read -r line; do
    [[ -z "$line" ]] && continue
    comment=$(echo "$line" | awk '{print $NF}')
    echo "  - $comment"
done < "$REPO_ROOT/remote/authorized_keys"
