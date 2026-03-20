#!/usr/bin/env bash
set -euo pipefail

VM="${1:-}"

if [[ -z "$VM" ]]; then
    echo "Usage: $0 <vm-name>"
    echo ""
    echo "Available VMs:"
    virsh list --all --name | grep -v '^$'
    exit 1
fi

echo "Starting VM: $VM"
virsh start "$VM"
