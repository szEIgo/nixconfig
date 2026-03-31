#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Master NixOS Installer (UEFI vs. Legacy Toggle)
#
# Installs a minimal NixOS with SSH + flakes enabled.
# After reboot: clone nixconfig, then nixos-rebuild switch --flake .#<hostname>
# =============================================================================

BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Master NixOS Installer ===${NC}"

# ---- 1. Disk Selection ----
lsblk -d -o NAME,SIZE,MODEL,TYPE | grep disk
read -p "Enter disk (e.g. sda): " DISK_NAME
DISK="/dev/${DISK_NAME}"
[[ ! -b "$DISK" ]] && echo "Disk not found!" && exit 1

# ---- 2. Mode Selection ----
echo -e "\n${YELLOW}Which boot mode are you using?${NC}"
echo "1) UEFI (Modern - GPT, systemd-boot)"
echo "2) Legacy (Old - MBR, GRUB)"
read -p "Selection [1-2]: " MODE

# ---- 3. Setup Info ----
read -p "Hostname [nuc]: " HOSTNAME
HOSTNAME="${HOSTNAME:-nuc}"
read -p "Username [joni]: " USERNAME
USERNAME="${USERNAME:-joni}"

while true; do
    read -sp "Password: " PASSWORD
    echo ""
    read -sp "Confirm: " PASSWORD2
    echo ""
    [[ "$PASSWORD" == "$PASSWORD2" ]] && break
    echo "Passwords match failed!"
done

# ---- 4. Partitioning Logic ----
echo -e "${BLUE}Wiping and Partitioning...${NC}"
HASHED_PASSWORD=$(echo "$PASSWORD" | mkpasswd -m sha-512 -s)

if [[ "$MODE" == "1" ]]; then
    # UEFI MODE
    parted "$DISK" -- mklabel gpt
    parted "$DISK" -- mkpart ESP fat32 1MiB 512MiB
    parted "$DISK" -- set 1 esp on
    parted "$DISK" -- mkpart primary ext4 512MiB 100%

    PART_BOOT="${DISK}$([[ "$DISK_NAME" == nvme* ]] && echo "p1" || echo "1")"
    PART_ROOT="${DISK}$([[ "$DISK_NAME" == nvme* ]] && echo "p2" || echo "2")"

    mkfs.fat -F 32 -n BOOT "$PART_BOOT"
    mkfs.ext4 -F -L nixos "$PART_ROOT"

    mount "$PART_ROOT" /mnt
    mkdir -p /mnt/boot
    mount "$PART_BOOT" /mnt/boot

    BOOT_CONFIG="boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;"
else
    # LEGACY MODE
    parted "$DISK" -- mklabel msdos
    parted "$DISK" -- mkpart primary ext4 1MiB 100%
    parted "$DISK" -- set 1 boot on

    PART_ROOT="${DISK}$([[ "$DISK_NAME" == nvme* ]] && echo "p1" || echo "1")"

    mkfs.ext4 -F -L nixos "$PART_ROOT"
    mount "$PART_ROOT" /mnt

    BOOT_CONFIG="boot.loader.grub.enable = true;
  boot.loader.grub.device = \"$DISK\";"
fi

# ---- 5. Generate hardware config (auto-detects drivers) ----
echo -e "${BLUE}Detecting hardware...${NC}"
nixos-generate-config --root /mnt

# ---- 6. Write configuration (keep auto-detected hardware-configuration.nix) ----
cat > /mnt/etc/nixos/configuration.nix << NIXEOF
{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];
  ${BOOT_CONFIG}
  networking.hostName = "${HOSTNAME}";
  networking.useDHCP = true;

  # Flakes (needed to apply nixconfig after first boot)
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # SSH
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # Git (needed to clone nixconfig)
  environment.systemPackages = with pkgs; [ git ];

  # Users
  users.users.root.hashedPassword = "${HASHED_PASSWORD}";
  users.users.${USERNAME} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = "${HASHED_PASSWORD}";
  };
  system.stateVersion = "25.11";
}
NIXEOF

# ---- 7. Finalize ----
echo -e "${BLUE}Installing NixOS...${NC}"
nixos-install --no-root-passwd
echo -e "${GREEN}Done! After reboot:${NC}"
echo ""
echo "  git clone https://github.com/szeigo/nixconfig.git ~/nixconfig"
echo "  cd ~/nixconfig"
echo "  sudo nixos-rebuild switch --flake .#${HOSTNAME}"
echo ""
reboot
