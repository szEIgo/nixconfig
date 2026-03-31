#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Headless NixOS Installer (Adaptive Bootloader - Fixed)
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
lsblk -d -o NAME,SIZE,MODEL,TYPE | grep disk
echo ""
read -p "Enter disk to install on (e.g. nvme0n1, sda): " DISK_NAME
DISK="/dev/${DISK_NAME}"

if [[ ! -b "$DISK" ]]; then
    echo -e "${RED}Error: $DISK does not exist${NC}"
    exit 1
fi

PART_PREFIX=$([[ "$DISK_NAME" == nvme* ]] && echo "${DISK}p" || echo "${DISK}")

# ---- Bootloader Selection ----
echo ""
echo -e "${YELLOW}Choose Bootloader:${NC}"
echo "1) systemd-boot (Modern, simple)"
echo -e "2) GRUB ${GREEN}(Recommended for old PCs / ThinkCentres)${NC}"
read -p "Selection [1-2]: " BOOT_CHOICE

# ---- Hostname & User ----
read -p "Hostname [nuc]: " HOSTNAME
HOSTNAME="${HOSTNAME:-nuc}"
read -p "Username [joni]: " USERNAME
USERNAME="${USERNAME:-joni}"

while true; do
    read -sp "Password for ${USERNAME}: " PASSWORD
    echo ""
    read -sp "Confirm password: " PASSWORD2
    echo ""
    [[ "$PASSWORD" == "$PASSWORD2" ]] && break
    echo -e "${RED}Passwords don't match!${NC}"
done

# ---- Confirm Wipe ----
echo -e "${RED}WARNING: Wiping ${DISK}!${NC}"
read -p "Type YES to continue: " CONFIRM
[[ "$CONFIRM" != "YES" ]] && exit 0

# ---- Partition & Format ----
echo -e "${BLUE}Partitioning...${NC}"
parted "$DISK" -- mklabel gpt
parted "$DISK" -- mkpart ESP fat32 1MiB 512MiB
parted "$DISK" -- set 1 boot on
parted "$DISK" -- set 1 esp on
parted "$DISK" -- mkpart primary 512MiB 100%

mkfs.fat -F 32 -n BOOT "${PART_PREFIX}1"
mkfs.ext4 -F -L nixos "${PART_PREFIX}2"

# ---- Mount ----
mount "${PART_PREFIX}2" /mnt
mkdir -p /mnt/boot
mount "${PART_PREFIX}1" /mnt/boot

# ---- Generate Configs ----
nixos-generate-config --root /mnt
HASHED_PASSWORD=$(echo "$PASSWORD" | mkpasswd -m sha-512 -s)

# Setup Bootloader Logic (Corrected for conflict)
if [[ "$BOOT_CHOICE" == "2" ]]; then
    BOOT_CONFIG="boot.loader.grub.enable = true;
  boot.loader.grub.device = \"nodev\";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.efi.canTouchEfiVariables = false;"
else
    BOOT_CONFIG="boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;"
fi

# Write Hardware Config
cat > /mnt/etc/nixos/hardware-configuration.nix << HWEOF
{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "ata_piix" "uhci_hcd" ];
  fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
  fileSystems."/boot" = { device = "/dev/disk/by-label/BOOT"; fsType = "vfat"; options = [ "fmask=0022" "dmask=0022" ]; };
}
HWEOF

# Write Main Config
cat > /mnt/etc/nixos/configuration.nix << NIXEOF
{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];
  
  ${BOOT_CONFIG}

  networking.hostName = "${HOSTNAME}";
  networking.useDHCP = true;
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

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
nixos-install --no-root-passwd

echo -e "${GREEN}Done! Rebooting...${NC}"
sleep 2
reboot