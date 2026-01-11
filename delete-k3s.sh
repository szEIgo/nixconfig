#!/usr/bin/env bash
set -euo pipefail

# Wipes local k3s state (server/agent) on this host.
# Designed for NixOS-managed k3s where systemctl disable/enable isn't persistent.
# Safe-ish: stops services, unmounts lingering kubelet/containerd mounts, then deletes state directories.

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  exec sudo -E "$0" "$@"
fi

MASK=0
if [[ ${1:-} == "--mask" ]]; then
  MASK=1
  shift
fi

echo "[k3s-wipe] Stopping k3s services"
# These unit names exist on most k3s installs; ignore if missing.
systemctl stop k3s 2>/dev/null || true
systemctl stop k3s-agent 2>/dev/null || true

# Prevent immediate respawn while we're deleting (optional)
if (( MASK )); then
  echo "[k3s-wipe] Masking units (will require unmask later)"
  systemctl mask k3s 2>/dev/null || true
  systemctl mask k3s-agent 2>/dev/null || true
fi

# Best-effort kill remaining processes from the units.
systemctl kill --kill-who=all k3s 2>/dev/null || true
systemctl kill --kill-who=all k3s-agent 2>/dev/null || true
systemctl reset-failed k3s 2>/dev/null || true
systemctl reset-failed k3s-agent 2>/dev/null || true

# Unmount anything still mounted under common k3s/kubelet paths.
# This is what typically causes "Device or resource busy" during rm -rf.
unmount_prefixes=(
  /var/lib/kubelet
  /run/k3s
  /run/flannel
  /var/lib/rancher/k3s
)

if command -v findmnt >/dev/null 2>&1; then
  for p in "${unmount_prefixes[@]}"; do
    [[ -e "$p" ]] || continue

    # Unmount deeper mountpoints first.
    mapfile -t mount_targets < <(findmnt -Rno TARGET "$p" 2>/dev/null | sort -r || true)
    for m in "${mount_targets[@]}"; do
      umount "$m" 2>/dev/null || true
    done

    # Then try recursive unmount (and lazy recursive as fallback).
    umount -R "$p" 2>/dev/null || true
    umount -R -l "$p" 2>/dev/null || true
  done
else
  # Fallback if findmnt isn't available.
  for p in "${unmount_prefixes[@]}"; do
    [[ -e "$p" ]] || continue
    umount -R "$p" 2>/dev/null || true
    umount -R -l "$p" 2>/dev/null || true
  done
fi

echo "[k3s-wipe] Removing k3s state directories"
rm -rf /var/lib/rancher/k3s \
  /etc/rancher/k3s \
  /var/lib/kubelet \
  /var/lib/cni \
  /etc/cni \
  /run/k3s \
  /run/flannel

# Clean up leftover network devices (may not exist).
ip link delete cni0 2>/dev/null || true
ip link delete flannel.1 2>/dev/null || true
ip link delete flannel.0 2>/dev/null || true

# Remove k3s-generated kubeconfig (client kubeconfig is handled separately).
rm -f /etc/rancher/k3s/k3s.yaml 2>/dev/null || true

echo "[k3s-wipe] Done"
if (( MASK )); then
  echo "[k3s-wipe] NOTE: units are masked. To re-enable, run: sudo systemctl unmask k3s k3s-agent"
fi
