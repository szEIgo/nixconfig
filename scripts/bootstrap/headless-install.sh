#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Headless NixOS Installer
#
# Run from a NixOS live ISO. Partitions a disk with labels (not UUIDs),
# installs a minimal NixOS, and leaves the machine ready for flake deployment.
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Headless NixOS Installer ===${NC}"
echo ""

# ---- Disk selection ----
echo -e "${YELLOW}Available disks:${NC}"
echo ""
lsblk -d -o NAME,SIZE,MODEL,TYPE | grep disk
echo ""

read -p "Enter disk to install on (e.g. nvme0n1, sda): " DISK_NAME
DISK="/dev/${DISK_NAME}"

if [[ ! -b "$DISK" ]]; then
    echo -e "${RED}Error: $DISK does not exist${NC}"
    exit 1
fi

# Detect partition suffix (nvme uses p1, sda uses 1)
if [[ "$DISK_NAME" == nvme* ]]; then
    PART_PREFIX="${DISK}p"
else
    PART_PREFIX="${DISK}"
fi

echo ""
echo -e "${RED}WARNING: This will WIPE ${DISK} completely!${NC}"
lsblk "$DISK"
echo ""
read -p "Type YES to continue: " CONFIRM
if [[ "$CONFIRM" != "YES" ]]; then
    echo "Aborted."
    exit 0
fi

# ---- Hostname ----
echo ""
read -p "Hostname [nuc]: " HOSTNAME
HOSTNAME="${HOSTNAME:-nuc}"

# ---- User setup ----
echo ""
read -p "Username [joni]: " USERNAME
USERNAME="${USERNAME:-joni}"

while true; do
    read -sp "Password for ${USERNAME} (and root): " PASSWORD
    echo ""
    read -sp "Confirm password: " PASSWORD2
    echo ""
    if [[ "$PASSWORD" == "$PASSWORD2" ]]; then
        break
    fi
    echo -e "${RED}Passwords don't match, try again${NC}"
done

# ---- Partition ----
echo ""
echo -e "${BLUE}Partitioning ${DISK}...${NC}"
parted "$DISK" -- mklabel gpt
parted "$DISK" -- mkpart ESP fat32 1MiB 512MiB
parted "$DISK" -- set 1 esp on
parted "$DISK" -- mkpart primary 512MiB 100%

# ---- Format with labels ----
echo -e "${BLUE}Formatting with labels...${NC}"
mkfs.fat -F 32 -n BOOT "${PART_PREFIX}1"
mkfs.ext4 -F -L nixos "${PART_PREFIX}2"

# ---- Mount ----
echo -e "${BLUE}Mounting...${NC}"

# Refresh partition table and wait for labels to appear
partprobe "$DISK" 2>/dev/null || true
udevadm settle

mount "${PART_PREFIX}2" /mnt
mkdir -p /mnt/boot
mount "${PART_PREFIX}1" /mnt/boot

# ---- Generate hardware config ----
echo -e "${BLUE}Generating hardware config...${NC}"
nixos-generate-config --root /mnt

# ---- Write minimal configuration ----
echo -e "${BLUE}Writing configuration...${NC}"

HASHED_PASSWORD=$(echo "$PASSWORD" | mkpasswd -m sha-512 -s)

# Write hardware config with labels (replaces the generated one)
cat > /mnt/etc/nixos/hardware-configuration.nix << 'HWEOF'
{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [ ];
}
HWEOF

cat > /mnt/etc/nixos/configuration.nix << NIXEOF
{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "${HOSTNAME}";
  networking.useDHCP = true;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  users.users.root.hashedPassword = "${HASHED_PASSWORD}";

  users.users.${USERNAME} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = "${HASHED_PASSWORD}";
  };

  environment.systemPackages = with pkgs; [ git vim ];

  system.stateVersion = "25.11";
}
NIXEOF

# ---- Install ----
echo ""
echo -e "${BLUE}Installing NixOS...${NC}"
echo -e "  Hostname:  ${GREEN}${HOSTNAME}${NC}"
echo -e "  User:      ${GREEN}${USERNAME}${NC}"
echo -e "  Disk:      ${GREEN}${DISK}${NC}"
echo -e "  Labels:    ${GREEN}BOOT (EFI), nixos (root)${NC}"
echo ""

nixos-install --no-root-passwd

# ---- Done ----
echo ""
echo -e "${GREEN}=== Installation complete! ===${NC}"
echo ""
echo "Next steps:"
echo "  1. Reboot into the new system"
echo "  2. SSH in:  ssh ${USERNAME}@<dhcp-ip>"
echo "  3. Clone:   git clone https://github.com/szeigo/nixconfig ~/nixconfig"
echo "  4. Apply:   cd ~/nixconfig && sudo nixos-rebuild switch --flake .#${HOSTNAME}"
echo ""
echo -e "${YELLOW}The flake will switch to static IP, lock down SSH, and set up k3s.${NC}"
echo ""
read -p "Reboot now? [y/N]: " DO_REBOOT
if [[ "$DO_REBOOT" =~ ^[yY]$ ]]; then
    umount -R /mnt
    reboot
fi
