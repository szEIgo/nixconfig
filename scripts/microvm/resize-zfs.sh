#!/usr/bin/env bash
set -euo pipefail

# Hot-resize ZFS volume for a MicroVM
# Usage: resize-zfs.sh <worker-id> <new-size>
# Example: resize-zfs.sh 1 20G

POOL="${ZFS_POOL:-fastPool}"
WORKER_ID="${1:-}"
NEW_SIZE="${2:-}"

if [[ -z "$WORKER_ID" || -z "$NEW_SIZE" ]]; then
  echo "Usage: $0 <worker-id> <new-size>"
  echo "Example: $0 1 20G"
  echo ""
  echo "Current volumes:"
  zfs list -o name,volsize,used -r "${POOL}/microvm" 2>/dev/null | grep k3s-worker || echo "  No volumes found"
  exit 1
fi

ZVOL="${POOL}/microvm/k3s-worker-${WORKER_ID}"
DEV="/dev/zvol/${ZVOL}"

# Elevate to root if needed
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  exec sudo -E "$0" "$@"
fi

# Check zvol exists
if ! zfs list "${ZVOL}" &>/dev/null; then
  echo "Error: ${ZVOL} does not exist"
  exit 1
fi

CURRENT_SIZE=$(zfs get -H -o value volsize "${ZVOL}")
echo "=== MicroVM ZFS Hot Resize ==="
echo "Volume: ${ZVOL}"
echo "Current size: ${CURRENT_SIZE}"
echo "New size: ${NEW_SIZE}"
echo ""

# Resize the zvol
echo "Resizing zvol..."
zfs set volsize="${NEW_SIZE}" "${ZVOL}"

# Wait for device to update
sleep 1
udevadm settle

# Check if VM is running and resize filesystem inside
if systemctl is-active --quiet "microvm@k3s-worker-${WORKER_ID}.service"; then
  echo ""
  echo "MicroVM is running. To resize the filesystem inside the VM:"
  echo "  1. SSH into the VM: make microvm-ssh VM=k3s-worker-${WORKER_ID}"
  echo "  2. Run: sudo resize2fs /dev/vda"
  echo ""
  echo "Or stop the VM and resize offline:"
  echo "  make microvm-stop VM=k3s-worker-${WORKER_ID}"
  echo "  sudo e2fsck -f ${DEV}"
  echo "  sudo resize2fs ${DEV}"
  echo "  make microvm-start VM=k3s-worker-${WORKER_ID}"
else
  echo "MicroVM is stopped. Resizing filesystem offline..."
  e2fsck -f "${DEV}" || true
  resize2fs "${DEV}"
  echo "Filesystem resized."
fi

echo ""
echo "=== Done ==="
zfs list -o name,volsize,used "${ZVOL}"
