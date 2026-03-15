#!/usr/bin/env bash
set -euo pipefail

# Destroy ZFS volumes for MicroVMs
# WARNING: This will delete all data!

POOL="${ZFS_POOL:-fastPool}"
WORKERS="${WORKERS:-3}"

echo "=== MicroVM ZFS Volume Destruction ==="
echo "Pool: $POOL"
echo "Workers: $WORKERS"
echo ""
echo "WARNING: This will DESTROY all MicroVM data!"
read -p "Type 'yes' to confirm: " confirm

if [[ "$confirm" != "yes" ]]; then
  echo "Aborted."
  exit 0
fi

# Elevate to root if needed
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  exec sudo -E "$0" "$@"
fi

# Stop all MicroVMs first
echo "Stopping MicroVMs..."
for i in $(seq 1 "$WORKERS"); do
  systemctl stop "microvm@k3s-worker-${i}.service" 2>/dev/null || true
done

# Destroy zvols
for i in $(seq 1 "$WORKERS"); do
  ZVOL="${POOL}/microvm/k3s-worker-${i}"
  if zfs list "${ZVOL}" &>/dev/null; then
    echo "Destroying: ${ZVOL}"
    zfs destroy "${ZVOL}"
  fi
done

# Destroy parent dataset if empty
if zfs list "${POOL}/microvm" &>/dev/null; then
  if [[ -z $(zfs list -H -o name -r "${POOL}/microvm" | tail -n +2) ]]; then
    echo "Destroying parent dataset: ${POOL}/microvm"
    zfs destroy "${POOL}/microvm"
  else
    echo "Parent dataset not empty, keeping it"
  fi
fi

echo ""
echo "=== Done ==="
