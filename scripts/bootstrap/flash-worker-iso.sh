#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Build and flash the worker ISO to a USB drive
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Worker ISO Flasher ===${NC}"
echo ""

# ---- 1. Build ISO ----
echo -e "${BLUE}Building worker ISO...${NC}"
nix build "$REPO_ROOT#images.worker-iso" --out-link "$REPO_ROOT/result-iso"
ISO_PATH=$(find "$REPO_ROOT/result-iso/" -name '*.iso' 2>/dev/null | head -1)

if [[ -z "$ISO_PATH" ]]; then
    echo -e "${RED}Failed to find ISO after build${NC}"
    exit 1
fi

ISO_SIZE=$(du -h "$ISO_PATH" | cut -f1)
echo -e "${GREEN}ISO ready:${NC} $(basename "$ISO_PATH") ($ISO_SIZE)"
echo ""

# ---- 2. List removable drives ----
echo -e "${YELLOW}Available removable drives:${NC}"
echo ""

DRIVES=()
while IFS= read -r line; do
    [[ -n "$line" ]] && DRIVES+=("$line")
done < <(lsblk -d -o NAME,SIZE,MODEL,TRAN,RM -rn | awk '$4 == "usb" || $5 == "1" { print $0 }')

if [[ ${#DRIVES[@]} -eq 0 ]]; then
    echo -e "${RED}No removable USB drives found.${NC}"
    echo "Insert a USB drive and try again."
    exit 1
fi

for i in "${!DRIVES[@]}"; do
    NAME=$(echo "${DRIVES[$i]}" | awk '{print $1}')
    SIZE=$(echo "${DRIVES[$i]}" | awk '{print $2}')
    MODEL=$(lsblk -d -o MODEL -n "/dev/$NAME" | xargs)
    echo -e "  ${GREEN}$((i+1)))${NC} /dev/${NAME}  ${SIZE}  ${MODEL}"
done

echo ""
read -p "Select drive [1-${#DRIVES[@]}]: " SELECTION

if [[ -z "$SELECTION" ]] || [[ "$SELECTION" -lt 1 ]] || [[ "$SELECTION" -gt ${#DRIVES[@]} ]]; then
    echo -e "${RED}Invalid selection${NC}"
    exit 1
fi

DISK_NAME=$(echo "${DRIVES[$((SELECTION-1))]}" | awk '{print $1}')
DISK="/dev/${DISK_NAME}"
DISK_SIZE=$(echo "${DRIVES[$((SELECTION-1))]}" | awk '{print $2}')
DISK_MODEL=$(lsblk -d -o MODEL -n "$DISK" | xargs)

echo ""
echo -e "${RED}WARNING: This will ERASE ALL DATA on ${DISK} (${DISK_MODEL} ${DISK_SIZE})${NC}"
read -p "Type 'yes' to continue: " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted."
    exit 0
fi

# ---- 3. Flash ----
echo ""
echo -e "${BLUE}Flashing ISO to ${DISK}...${NC}"
sudo dd if="$ISO_PATH" of="$DISK" bs=4M status=progress conv=fsync
sync

echo ""
echo -e "${GREEN}=== Done! ===${NC}"
echo ""
echo "Boot a worker node from this USB, then from mothership run:"
echo ""
echo -e "  ${YELLOW}make deploy-worker HOST=<hostname> IP=<ip>${NC}"
