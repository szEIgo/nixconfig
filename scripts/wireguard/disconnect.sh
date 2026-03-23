#!/usr/bin/env bash
set -euo pipefail

HOSTNAME=$(hostname)

if [ "$HOSTNAME" = "mothership" ]; then
    echo "Error: mothership is the WireGuard server — it should stay running."
    exit 1
fi

echo "Bringing down WireGuard tunnel (wg0)..."
sudo systemctl stop wg-quick-wg0.service

echo "WireGuard disconnected."
