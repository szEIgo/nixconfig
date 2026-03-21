# Headless Getting Started (NUC / Remote Machines)

Install NixOS on a headless machine by preparing the disk on another computer.
Uses filesystem labels (`/dev/disk/by-label/`) instead of UUIDs so the disk
can be moved between machines without boot issues.

**Navigation:** [README](../README.md) | [Getting Started](getting-started.md) | [Usage](usage.md)

---

## Prerequisites

- A laptop/workstation running NixOS (or the NixOS live ISO)
- The target machine's disk (NVMe/SSD) connected to the laptop (directly or via USB adapter)
- This nixconfig repo cloned on the laptop

---

## 1. Identify the Disk

```bash
lsblk
```

Find the target disk (e.g. `/dev/nvme0n1` or `/dev/sda`). **Double-check** you're
targeting the right drive — this will wipe it.

```bash
DISK=/dev/nvme0n1    # adjust to your disk
```

## 2. Partition

```bash
# Create GPT partition table
parted $DISK -- mklabel gpt

# EFI system partition (512MB)
parted $DISK -- mkpart ESP fat32 1MiB 512MiB
parted $DISK -- set 1 esp on

# Root partition (rest of disk)
parted $DISK -- mkpart primary 512MiB 100%
```

## 3. Format with Labels

Labels make the disk portable between machines — no UUID mismatches.

```bash
# EFI partition (FAT32 uppercases labels automatically)
mkfs.fat -F 32 -n BOOT ${DISK}p1

# Root partition
mkfs.ext4 -L nixos ${DISK}p2
```

Verify:
```bash
lsblk -o NAME,LABEL,FSTYPE $DISK
# Should show: BOOT (vfat) and nixos (ext4)
```

## 4. Mount

```bash
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/BOOT /mnt/boot
```

## 5. Generate Config

```bash
nixos-generate-config --root /mnt
```

This creates `/mnt/etc/nixos/configuration.nix` and `hardware-configuration.nix`.

## 6. Edit the Generated Config

Edit `/mnt/etc/nixos/configuration.nix` to add the minimum needed for first boot:

```bash
vim /mnt/etc/nixos/configuration.nix
```

Add/ensure these lines:

```nix
{ config, lib, pkgs, ... }: {
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking — just enough to get online after first boot
  networking.hostName = "nuc";
  networking.useDHCP = true;    # DHCP for first boot, static IP applied later via flake

  # Enable SSH so you can connect headlessly after moving the disk
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";  # temporary, flake locks this down

  # Set a root password so you can log in
  users.users.root.initialPassword = "changeme";

  # Create your user
  users.users.joni = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "changeme";
  };

  system.stateVersion = "25.11";
}
```

Also verify that `/mnt/etc/nixos/hardware-configuration.nix` uses labels (it should
since we formatted with them):

```bash
grep "by-label" /mnt/etc/nixos/hardware-configuration.nix
# Should show: /dev/disk/by-label/nixos and /dev/disk/by-label/BOOT
```

If it uses UUIDs instead, replace them:
```nix
fileSystems."/" = {
  device = "/dev/disk/by-label/nixos";
  fsType = "ext4";
};
fileSystems."/boot" = {
  device = "/dev/disk/by-label/BOOT";
  fsType = "vfat";
};
```

## 7. Install

```bash
nixos-install
```

Set the root password when prompted (this is temporary — the flake config will
manage users and SSH keys later).

## 8. Move Disk to Target Machine

```bash
umount /mnt/boot
umount /mnt
```

1. Remove the disk from the laptop
2. Insert it into the NUC
3. Boot the NUC
4. It will get a DHCP address — find it on your router or with `nmap -sn 192.168.2.0/24`

## 9. SSH In and Apply Flake Config

```bash
ssh joni@<nuc-dhcp-ip>    # password: changeme
```

From the NUC:

```bash
# Install git (not in minimal config)
nix-shell -p git

# Clone the repo
git clone https://github.com/szeigo/nixconfig ~/nixconfig
cd ~/nixconfig

# Apply the NUC configuration
sudo nixos-rebuild switch --flake .#nuc
```

This will:
- Switch to static IP `192.168.2.211`
- Lock down SSH (key-only, no root password login)
- Set up k3s agent
- Install your full shell config (zsh, p10k, all CLI tools)

**Note:** After the switch, your SSH connection will drop since the IP changes
from DHCP to `192.168.2.211`. Reconnect:

```bash
ssh joni@192.168.2.211
```

## 10. Join k3s Cluster

Copy the join token from the mothership:

```bash
# On the mothership
sudo cat /var/lib/rancher/k3s/server/node-token
```

Place it on the NUC:

```bash
# On the NUC
sudo mkdir -p /etc/k3s
sudo vim /etc/k3s/token
# Paste the token content

# Restart k3s to pick up the token
sudo systemctl restart k3s-agent
```

Verify on the mothership:

```bash
kubectl get nodes
# Should show the NUC as a worker node
```

---

## Troubleshooting

### "waiting for /dev/disk/by-uuid/..." on boot

The config references a UUID instead of a label. Boot from NixOS ISO, mount the
root partition, and fix `hardware-configuration.nix` to use `/dev/disk/by-label/`.

### Can't find the NUC on the network

- Check that the NUC is actually booting (connect a monitor temporarily)
- Verify DHCP is enabled in the initial config
- Try `nmap -sn 192.168.2.0/24` from your laptop

### SSH connection refused

- Ensure `services.openssh.enable = true` is in the config
- Check the NUC's firewall: the initial config should allow SSH by default

---

**Next:** [Daily Usage](usage.md) | [Getting Started (Desktop)](getting-started.md)
