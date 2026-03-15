#!/usr/bin/env bash
set -euo pipefail

# Build and switch to NixOS configuration (interactive)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOST="${1:-mothership}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}NixOS Configuration Switch${NC}"
echo "Host: $HOST"
echo ""

# Available configurations
echo -e "${YELLOW}Available configurations:${NC}"
echo ""
echo -e "  ${RED}0) base (headless)${NC}"
echo "     - No desktop environment"
echo "     - All GPUs bound to vfio-pci"
echo "     - For VM passthrough host only"
echo ""
echo -e "  ${GREEN}1) amd${NC}"
echo "     - AMD GPU for desktop (Hyprland + Plasma)"
echo "     - NVIDIA GPU passed to VMs"
echo "     - Steam gaming enabled"
echo ""
echo -e "  ${GREEN}2) nvidia${NC}"
echo "     - NVIDIA GPU for desktop (Hyprland + Plasma)"
echo "     - AMD GPU passed to VMs"
echo ""
echo -e "  ${GREEN}3) dualGpu${NC}"
echo "     - Both GPUs available to host"
echo "     - Hyprland + Plasma desktop"
echo ""

# Get user choice
read -p "Select configuration [1-3, 0 for headless, q to quit]: " choice

case "$choice" in
    0)
        CONFIG="base"
        SPEC=""
        echo -e "\n${RED}WARNING: This will switch to HEADLESS mode!${NC}"
        echo "Your desktop environment will stop working."
        read -p "Are you absolutely sure? (yes/no): " confirm
        if [[ "$confirm" != "yes" ]]; then
            echo "Aborted."
            exit 0
        fi
        ;;
    1)
        CONFIG="amd"
        SPEC="amd"
        ;;
    2)
        CONFIG="nvidia"
        SPEC="nvidia"
        ;;
    3)
        CONFIG="dualGpu"
        SPEC="dualGpu"
        ;;
    q|Q)
        echo "Aborted."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice. Aborted.${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}Switching to: ${GREEN}$CONFIG${NC}"
echo ""

if [[ -n "$SPEC" ]]; then
    # Build and switch, then activate specialisation
    echo "Building configuration..."
    sudo nixos-rebuild switch --flake "$REPO_ROOT#$HOST"

    echo ""
    echo "Activating specialisation: $SPEC"
    sudo /run/current-system/specialisation/$SPEC/bin/switch-to-configuration switch
else
    # Base config (headless)
    sudo nixos-rebuild switch --flake "$REPO_ROOT#$HOST"
fi

echo ""
echo -e "${GREEN}Switch complete!${NC}"
