#!/usr/bin/env bash
set -euo pipefail

# Wipes local k3s state (server/agent) on this host
# Stops services, unmounts kubelet/containerd mounts, deletes state directories

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    exec sudo -E "$0" "$@"
fi

MASK=0
if [[ ${1:-} == "--mask" ]]; then
    MASK=1
    shift
fi

echo "[k3s-wipe] Stopping k3s services"
systemctl stop k3s 2>/dev/null || true
systemctl stop k3s-agent 2>/dev/null || true

if (( MASK )); then
    echo "[k3s-wipe] Masking units"
    systemctl mask k3s 2>/dev/null || true
    systemctl mask k3s-agent 2>/dev/null || true
fi

systemctl kill --kill-who=all k3s 2>/dev/null || true
systemctl kill --kill-who=all k3s-agent 2>/dev/null || true
systemctl reset-failed k3s 2>/dev/null || true
systemctl reset-failed k3s-agent 2>/dev/null || true

unmount_prefixes=(
    /var/lib/kubelet
    /run/k3s
    /run/flannel
    /var/lib/rancher/k3s
)

for p in "${unmount_prefixes[@]}"; do
    [[ -e "$p" ]] || continue
    if command -v findmnt >/dev/null 2>&1; then
        mapfile -t mount_targets < <(findmnt -Rno TARGET "$p" 2>/dev/null | sort -r || true)
        for m in "${mount_targets[@]}"; do
            umount "$m" 2>/dev/null || true
        done
    fi
    umount -R "$p" 2>/dev/null || true
    umount -R -l "$p" 2>/dev/null || true
done

echo "[k3s-wipe] Removing k3s state directories"
rm -rf /var/lib/rancher/k3s \
    /etc/rancher/k3s \
    /var/lib/kubelet \
    /var/lib/cni \
    /etc/cni \
    /run/k3s \
    /run/flannel

ip link delete cni0 2>/dev/null || true
ip link delete flannel.1 2>/dev/null || true
ip link delete flannel.0 2>/dev/null || true

rm -f /etc/rancher/k3s/k3s.yaml 2>/dev/null || true

echo "[k3s-wipe] Done"
if (( MASK )); then
    echo "[k3s-wipe] Units masked. To re-enable: sudo systemctl unmask k3s k3s-agent"
fi
