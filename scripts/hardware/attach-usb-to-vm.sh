#!/usr/bin/env bash
set -euo pipefail

# Attach USB devices (keyboard + mouse receiver) to Windows VM

VM_NAME="${1:-win11-nvidia}"

KEYBOARD_VENDOR_ID="0x03f0"
KEYBOARD_PRODUCT_ID="0x0024"
LIGHTSPEED_VENDOR_ID="0x046d"
LIGHTSPEED_PRODUCT_ID="0xc08b"

echo "Attaching USB devices to $VM_NAME..."

virsh attach-device "$VM_NAME" <(cat <<EOF
<hostdev mode='subsystem' type='usb'>
  <source>
    <vendor id='$KEYBOARD_VENDOR_ID'/>
    <product id='$KEYBOARD_PRODUCT_ID'/>
  </source>
</hostdev>
EOF
) --persistent --config

virsh attach-device "$VM_NAME" <(cat <<EOF
<hostdev mode='subsystem' type='usb'>
  <source>
    <vendor id='$LIGHTSPEED_VENDOR_ID'/>
    <product id='$LIGHTSPEED_PRODUCT_ID'/>
  </source>
</hostdev>
EOF
) --persistent --config

echo "USB devices attached."
