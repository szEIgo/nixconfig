#!/usr/bin/env bash
set -euo pipefail

echo "=== Libvirt VMs ==="
virsh list --all
