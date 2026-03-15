#!/usr/bin/env bash
set -euo pipefail

# Show detailed MicroVM status

VM="${1:-}"

if [[ -n "$VM" ]]; then
  echo "=== MicroVM: $VM ==="
  systemctl status "microvm@${VM}.service" --no-pager -l 2>/dev/null || echo "MicroVM '$VM' not found"
else
  echo "=== All MicroVMs ==="
  systemctl list-units 'microvm@*' --all --no-pager
fi
