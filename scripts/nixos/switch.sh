#!/usr/bin/env bash
set -euo pipefail

# Build and switch configuration (NixOS, nix-darwin, nix-on-droid)
# Usage: switch.sh [HOST] [SPEC]
#   HOST: hostname (default: mothership)
#         Use "macos" for nix-darwin, "android" for nix-on-droid
#   SPEC: specialisation (default: amd for mothership, none for others)
#         Use "base" for headless, "interactive" for menu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOST="${1:-mothership}"
SPEC="${2:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- nix-darwin (macOS) ---
if [[ "$HOST" == "macos" ]]; then
    echo -e "${BLUE}nix-darwin Switch${NC}"
    echo "Host: jsz-mac-01"
    echo ""
    echo "Building configuration..."
    # Unset Workbrew wrapper to avoid conflict when brew runs under sudo
    unset HOMEBREW_FORCE_BREW_WRAPPER 2>/dev/null || true
    sudo -E darwin-rebuild switch --flake "$REPO_ROOT#jsz-mac-01"
    echo ""
    echo -e "${GREEN}Switch complete!${NC}"
    exit 0
fi

# --- nix-on-droid (Android) ---
if [[ "$HOST" == "android" ]]; then
    echo -e "${BLUE}nix-on-droid Switch${NC}"
    echo ""
    echo "Building configuration..."
    nix-on-droid switch --flake "$REPO_ROOT"
    echo ""
    echo -e "${GREEN}Switch complete!${NC}"
    exit 0
fi

# --- postmarketOS (OnePlus 6T) ---
if [[ "$HOST" == "oneplus6t" ]]; then
    echo -e "${BLUE}postmarketOS Switch (home-manager)${NC}"
    echo "Host: oneplus6t (user@192.168.2.187)"
    echo ""
    echo "Syncing configuration..."
    scp -q "$REPO_ROOT/flake.nix" user@192.168.2.187:/home/user/nixconfig/flake.nix
    scp -q "$REPO_ROOT/flake.lock" user@192.168.2.187:/home/user/nixconfig/flake.lock
    scp -rq "$REPO_ROOT/home" user@192.168.2.187:/home/user/nixconfig/
    scp -rq "$REPO_ROOT/hosts/oneplus6t" user@192.168.2.187:/home/user/nixconfig/hosts/
    scp -q "$REPO_ROOT/remote/authorized_keys" user@192.168.2.187:/home/user/nixconfig/remote/authorized_keys

    echo "Building on device..."
    STORE_PATH=$(ssh user@192.168.2.187 ". /home/user/.nix-profile/etc/profile.d/nix.sh && cd /home/user/nixconfig && nix run nixpkgs#git -- add -A 2>/dev/null && nix build .#homeConfigurations.oneplus6t.activationPackage --no-link --print-out-paths 2>&1 | tail -1")
    echo "Activating: $STORE_PATH"
    ssh -tt user@192.168.2.187 ". /home/user/.nix-profile/etc/profile.d/nix.sh && $STORE_PATH/activate"

    echo ""
    echo -e "${GREEN}Switch complete!${NC}"
    exit 0
fi

# --- NixOS ---

# Default specialisation per host
if [[ -z "$SPEC" ]]; then
    case "$HOST" in
        mothership)
            SPEC="amd"
            ;;
        *)
            SPEC=""
            ;;
    esac
fi

# Memory management: limit parallel builds to avoid OOM
NIX_JOBS="${NIX_JOBS:-2}"       # Max parallel builds
NIX_CORES="${NIX_CORES:-8}"     # Cores per build
NIX_OPTS="--max-jobs $NIX_JOBS --cores $NIX_CORES"

# Limit Nix evaluator memory (in bytes, ~8GB)
export GC_INITIAL_HEAP_SIZE="${GC_INITIAL_HEAP_SIZE:-2000000000}"

# Prevent systemd-run from opening a pager on failure
export SYSTEMD_PAGER=""

# Interactive mode
if [[ "$SPEC" == "interactive" ]]; then
    echo -e "${BLUE}NixOS Configuration Switch${NC}"
    echo "Host: $HOST"
    echo ""

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

    read -p "Select configuration [1-3, 0 for headless, q to quit]: " choice

    case "$choice" in
        0)
            SPEC="base"
            echo -e "\n${RED}WARNING: This will switch to HEADLESS mode!${NC}"
            echo "Your desktop environment will stop working."
            read -p "Are you absolutely sure? (yes/no): " confirm
            if [[ "$confirm" != "yes" ]]; then
                echo "Aborted."
                exit 0
            fi
            ;;
        1) SPEC="amd" ;;
        2) SPEC="nvidia" ;;
        3) SPEC="dualGpu" ;;
        q|Q)
            echo "Aborted."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Aborted.${NC}"
            exit 1
            ;;
    esac
fi

# Headless warning for base
if [[ "$SPEC" == "base" ]]; then
    echo -e "${RED}WARNING: Switching to HEADLESS mode (no desktop)${NC}"
fi

echo -e "${BLUE}NixOS Switch${NC}"
echo "Host: $HOST"
echo "Specialisation: ${SPEC:-base (none)}"
echo "Jobs: $NIX_JOBS parallel, $NIX_CORES cores each"
echo ""

# Build and switch
echo "Building configuration..."
if [[ -n "$SPEC" && "$SPEC" != "base" ]]; then
    sudo GC_INITIAL_HEAP_SIZE="$GC_INITIAL_HEAP_SIZE" nixos-rebuild switch --flake "$REPO_ROOT#$HOST" --specialisation "$SPEC" $NIX_OPTS
else
    sudo GC_INITIAL_HEAP_SIZE="$GC_INITIAL_HEAP_SIZE" nixos-rebuild switch --flake "$REPO_ROOT#$HOST" $NIX_OPTS
fi

echo ""
echo -e "${GREEN}Switch complete!${NC}"
