#!/usr/bin/env bash
set -euo pipefail

# Start MicroVM(s)
# Ensures k3s token is available before starting VMs
# Cleans up stale k3s node registrations if needed

VM="${1:-}"

# Clean up stale k3s worker nodes that are NotReady
# This handles the case where VMs were rebuilt and node passwords don't match
cleanup_stale_nodes() {
  echo "Checking for stale k3s worker nodes..."
  local stale_nodes
  stale_nodes=$(kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' 2>/dev/null | grep "k3s-worker" | grep -v "True" | awk '{print $1}' || true)

  if [[ -n "$stale_nodes" ]]; then
    echo "Found stale worker nodes, removing for re-registration:"
    for node in $stale_nodes; do
      echo "  Deleting node: $node"
      kubectl delete node "$node" 2>/dev/null || true
    done
  fi
}

# Ensure k3s token is available for microvms
echo "Ensuring k3s token is available..."
if ! sudo systemctl start microvm-k3s-token.service; then
  echo "ERROR: Failed to copy k3s token. Is k3s running?"
  exit 1
fi

# Clean up stale nodes before starting VMs
cleanup_stale_nodes

if [[ -z "$VM" ]] || [[ "$VM" == "all" ]]; then
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
