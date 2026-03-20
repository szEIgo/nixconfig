#!/usr/bin/env bash
set -euo pipefail

echo "Starting scrub on all pools..."

for pool in $(zpool list -H -o name); do
    echo "Scrubbing $pool..."
    sudo zpool scrub "$pool"
done

echo ""
echo "Scrub started. Check progress with: zpool status"
