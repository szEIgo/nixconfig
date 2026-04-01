#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Listen for fleet node announcements on UDP port 9999
#
# Boot a node from the worker ISO and it will announce its IP here.
# Press Ctrl+C to stop listening.
#
# Usage: fleet-listen.sh
# =============================================================================

PORT=9999

echo "Listening for fleet node announcements on UDP port $PORT..."
echo "Boot a node from the worker ISO — it will appear here."
echo "Press Ctrl+C to stop."
echo ""

# Check if socat is available
if ! command -v socat &>/dev/null; then
    echo "socat not found. Run: nix-shell -p socat --run './scripts/bootstrap/fleet-listen.sh'"
    exit 1
fi

socat -u UDP4-LISTEN:$PORT,reuseaddr,fork STDOUT | while read -r line; do
    TIMESTAMP=$(date '+%H:%M:%S')
    echo "[$TIMESTAMP] $line"
done
