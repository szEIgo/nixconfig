#!/usr/bin/env bash
set -euo pipefail

# Import and mount ZFS pools

if [[ "$(id -u)" -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

zpool import fastPool 2>/dev/null || true
zpool import slowPool 2>/dev/null || true
zfs load-key slowPool 2>/dev/null || true
zfs mount -a

echo "ZFS pools mounted"
