#!/usr/bin/env bash
set -euo pipefail

VM="${1:-}"

if [[ -z "$VM" ]]; then
    echo "Usage: $0 <vm-name>"
    echo ""
    echo "Running VMs:"
    virsh list --name | grep -v '^$'
    exit 1
fi

echo "Connecting to VM console: $VM"
echo "(Press Ctrl+] to exit)"
virsh console "$VM"
