#!/usr/bin/env bash
set -euo pipefail

# Remove loader/nvram entries from VM config (fixes EFI issues)

VM_NAME="${1:-win11-nvidia}"

virsh dumpxml "$VM_NAME" \
    | grep --invert-match --extended-regexp "<(loader|nvram).*>.*</(loader|nvram)>" \
    > /tmp/edited_vm_config.xml

virsh define /tmp/edited_vm_config.xml
rm /tmp/edited_vm_config.xml

echo "EFI entries removed from $VM_NAME"
