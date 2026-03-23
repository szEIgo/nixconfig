#!/usr/bin/env bash
set -euo pipefail

HOSTNAME=$(hostname)

if [ "$HOSTNAME" = "mothership" ]; then
    echo "Error: mothership is the WireGuard server — use 'wg show' to check status instead."
    exit 1
fi

echo "Bringing up WireGuard tunnel (wg0)..."
sudo systemctl start wg-quick-wg0.service

echo ""
echo "WireGuard connected:"
sudo wg show wg0
