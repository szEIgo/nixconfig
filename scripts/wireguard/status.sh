#!/usr/bin/env bash
set -euo pipefail

echo "WireGuard status:"
echo ""

if sudo wg show wg0 &>/dev/null; then
    sudo wg show wg0
    echo ""
    echo "Interface address:"
    ip -4 addr show wg0 2>/dev/null | grep inet || echo "  (no address assigned)"
else
    echo "  wg0 is not active."
    echo ""
    HOSTNAME=$(hostname)
    if [ "$HOSTNAME" = "mothership" ]; then
        echo "  Check: systemctl status systemd-networkd"
    else
        echo "  Run: make wg-connect"
    fi
fi
