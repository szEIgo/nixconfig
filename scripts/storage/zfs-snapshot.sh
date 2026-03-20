#!/usr/bin/env bash
set -euo pipefail

DATASET="${1:-}"

if [[ -z "$DATASET" ]]; then
    echo "Usage: $0 <dataset>"
    echo "Example: $0 rpool/nixos/home"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SNAPSHOT="${DATASET}@${TIMESTAMP}"

echo "Creating snapshot: $SNAPSHOT"
sudo zfs snapshot "$SNAPSHOT"
echo "Done."
