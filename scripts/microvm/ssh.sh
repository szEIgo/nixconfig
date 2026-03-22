#!/usr/bin/env bash
set -euo pipefail

# SSH into a MicroVM via VSOCK

VM="${1:-}"

if [[ -z "$VM" ]]; then
  echo "Usage: $0 <vm-name>"
  echo ""
  echo "Available MicroVMs:"
  systemctl list-units 'microvm@*' --all --no-legend --plain | awk '{print $1}' | grep '^microvm@' | while read -r unit; do
    name=$(echo "$unit" | sed 's/microvm@\(.*\)\.service/\1/')
    echo "  $name"
  done
  exit 1
fi

echo "Connecting to MicroVM: $VM"
microvm -s "$VM"
