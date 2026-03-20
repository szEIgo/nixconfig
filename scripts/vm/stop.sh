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

echo "Stopping VM: $VM (graceful shutdown)"
virsh shutdown "$VM"
echo "VM shutdown initiated. Force stop with: virsh destroy $VM"
