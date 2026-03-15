#!/usr/bin/env bash
set -euo pipefail

# Start a headless KDE Plasma session with VNC access

export WLR_BACKENDS=headless
export KWIN_WAYLAND_VIRTUAL_OUTPUTS=1

dbus-run-session startplasma-wayland &
sleep 3
wayvnc --output=VIRTUAL-1 0.0.0.0 5900
