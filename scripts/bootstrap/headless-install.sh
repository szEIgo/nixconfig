#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Headless NixOS Installer (Legacy/MBR version for ThinkCentre Edge 71)
# Use this if UEFI/GPT continues to give "Error 1962"
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Headless NixOS Installer (Legacy MBR Fix) ===${NC}"
echo ""

# ---- Disk selection ----
echo -e "${YELLOW}Available disks:${NC}"
lsblk -d -o NAME,SIZE,MODEL,TYPE | grep disk
echo ""
read -p "Enter disk to install on (e.g. sda): " DISK_NAME
DISK="/dev/${DISK_NAME}"

if [[ ! -b "$DISK" ]]; then
    echo -e "${RED}Error: $DISK does not exist${NC}"
    exit 1
fi

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
echo -e "${RED}WARNING: This wipes ${DISK} and uses MBR (Legacy) mode!${NC}"
read -p "Type YES to continue: " CONFIRM
[[ "$CONFIRM" != "YES" ]] && exit 0

# ---- Partition & Format (Legacy MBR) ----
echo -e "${BLUE}Partitioning for Legacy Boot...${NC}"
# Use msdos label for maximum compatibility with old BIOS
parted "$DISK" -- mklabel msdos
parted "$DISK" -- mkpart primary ext4 1MiB 100%
parted "$DISK" -- set 1 boot on

# We only have one partition in Legacy mode
mkfs.ext4 -F -L nixos "${DISK}1"

# ---- Mount ----
mount "${DISK}1" /mnt

# ---- Generate Configs ----
nixos-generate-config --root /mnt
HASHED_PASSWORD=$(echo "$PASSWORD" | mkpasswd -m sha-512 -s)

# Write Hardware Config (Simplified for Legacy)
cat > /mnt/etc/nixos/hardware-configuration.nix << HWEOF
{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "ata_piix" "uhci_hcd" ];
  fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
}
HWEOF

# Write Main Config (GRUB Legacy Mode)
cat > /mnt/etc/nixos/configuration.nix << NIXEOF
{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];
  
  # Legacy GRUB - No EFI
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "${DISK}"; 
  boot.loader.grub.efiSupport = false;

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