#!/usr/bin/env bash
set -euo pipefail

# Start MicroVM(s)

VM="${1:-}"

if [[ -z "$VM" ]]; then
  echo "Starting all MicroVMs..."
  systemctl list-units 'microvm@*' --all --no-legend | while read -r unit _rest; do
    echo "  Starting $unit"
    sudo systemctl start "$unit"
  done
elif [[ "$VM" == "all" ]]; then
  echo "Starting all MicroVMs..."
  systemctl list-units 'microvm@*' --all --no-legend | while read -r unit _rest; do
    echo "  Starting $unit"
    sudo systemctl start "$unit"
  done
else
  echo "Starting MicroVM: $VM"
  sudo systemctl start "microvm@${VM}.service"
fi

echo "Done."
