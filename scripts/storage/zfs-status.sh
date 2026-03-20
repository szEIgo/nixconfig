#!/usr/bin/env bash
set -euo pipefail

echo "=== ZFS Pool Status ==="
zpool status

echo ""
echo "=== Pool Space ==="
zpool list

echo ""
echo "=== Datasets ==="
zfs list -o name,used,avail,refer,mountpoint
