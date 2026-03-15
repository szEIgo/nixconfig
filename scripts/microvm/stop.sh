#!/usr/bin/env bash
set -euo pipefail

# Stop MicroVM(s)

VM="${1:-}"

if [[ -z "$VM" ]]; then
  echo "Usage: $0 <vm-name|all>"
  echo ""
  echo "Available MicroVMs:"
  systemctl list-units 'microvm@*' --all --no-legend | while read -r unit _rest; do
    name=$(echo "$unit" | sed 's/microvm@\(.*\)\.service/\1/')
    echo "  $name"
  done
  exit 1
elif [[ "$VM" == "all" ]]; then
  echo "Stopping all MicroVMs..."
  systemctl list-units 'microvm@*' --all --no-legend | while read -r unit _rest; do
    echo "  Stopping $unit"
    sudo systemctl stop "$unit"
  done
else
  echo "Stopping MicroVM: $VM"
  sudo systemctl stop "microvm@${VM}.service"
fi

echo "Done."
