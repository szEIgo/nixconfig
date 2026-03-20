#!/usr/bin/env bash
set -euo pipefail

# List all MicroVMs and their status

echo "=== MicroVMs ==="
systemctl list-units 'microvm@*' --all --no-legend | while read -r unit load active sub desc; do
  name=$(echo "$unit" | sed 's/microvm@\(.*\)\.service/\1/')
  printf "  %-20s %s\n" "$name" "$active"
done

if ! systemctl list-units 'microvm@*' --all --no-legend | grep -q .; then
  echo "  No MicroVMs found"
fi
