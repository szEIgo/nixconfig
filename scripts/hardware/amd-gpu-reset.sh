#!/usr/bin/env bash
set -euo pipefail

# Manual AMD GPU rescan for stuck GPUs after VM shutdown
# Uses PCI remove/rescan method - more forceful than vendor-reset

GPU_ID="0000:0d:00.0"
AUDIO_ID="0000:0d:00.1"

if [[ "$(id -u)" -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

echo "--- Starting AMD GPU Reset (PCI Rescan Method) ---"

echo "[1/4] Unbinding devices from vfio-pci..."
echo "$GPU_ID" > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null || true
echo "$AUDIO_ID" > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null || true
sleep 0.5

echo "[2/4] Removing devices from PCI bus..."
if [[ -e "/sys/bus/pci/devices/$GPU_ID/remove" ]]; then
    echo 1 > "/sys/bus/pci/devices/$GPU_ID/remove"
    echo 1 > "/sys/bus/pci/devices/$AUDIO_ID/remove"
else
    echo "ERROR: PCI remove file not found"
    exit 1
fi
sleep 0.5

echo "[3/4] Rescanning PCI bus..."
echo 1 > /sys/bus/pci/rescan
sleep 2

echo "[4/4] Rebinding devices to vfio-pci..."
if [[ ! -e "/sys/bus/pci/devices/$GPU_ID" ]]; then
    echo "ERROR: GPU did not reappear after rescan"
    exit 1
fi
echo "$GPU_ID" > /sys/bus/pci/drivers/vfio-pci/bind
echo "$AUDIO_ID" > /sys/bus/pci/drivers/vfio-pci/bind

echo "--- GPU reset complete ---"
