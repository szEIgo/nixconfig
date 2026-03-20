#!/usr/bin/env bash
set -euo pipefail

# Restart MicroVM(s)

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
  echo "Restarting all MicroVMs..."
  systemctl list-units 'microvm@*' --all --no-legend | while read -r unit _rest; do
    echo "  Restarting $unit"
    sudo systemctl restart "$unit"
  done
else
  echo "Restarting MicroVM: $VM"
  sudo systemctl restart "microvm@${VM}.service"
fi

echo "Done."
