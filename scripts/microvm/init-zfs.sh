#!/usr/bin/env bash
set -euo pipefail

# Initialize ZFS volumes for MicroVMs
# Run this once before starting MicroVMs with ZFS storage

POOL="${ZFS_POOL:-fastPool}"
SIZE="${ZFS_SIZE:-10G}"
WORKERS="${WORKERS:-3}"

echo "=== MicroVM ZFS Volume Setup ==="
echo "Pool: $POOL"
echo "Size per worker: $SIZE"
echo "Workers: $WORKERS"
echo ""

# Elevate to root if needed
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  exec sudo -E "$0" "$@"
fi

# Create parent dataset if it doesn't exist
if ! zfs list "${POOL}/microvm" &>/dev/null; then
  echo "Creating parent dataset: ${POOL}/microvm"
  zfs create "${POOL}/microvm"
else
  echo "Parent dataset ${POOL}/microvm already exists"
fi

# Create zvol for each worker
for i in $(seq 1 "$WORKERS"); do
  ZVOL="${POOL}/microvm/k3s-worker-${i}"
  DEV="/dev/zvol/${ZVOL}"

  if ! zfs list "${ZVOL}" &>/dev/null; then
    echo "Creating zvol: ${ZVOL} (${SIZE})"
    zfs create -V "$SIZE" "$ZVOL"

    # Wait for device to appear
    sleep 1
    udevadm settle

    echo "Formatting ${DEV} as ext4"
    mkfs.ext4 -L "k3s-worker-${i}" "$DEV"
  else
    echo "Zvol ${ZVOL} already exists"
  fi
done

echo ""
echo "=== Done ==="
echo "ZFS volumes ready. You can now start the MicroVMs."
zfs list -r "${POOL}/microvm"
