# Getting Started

Fresh system setup from zero to running.

**Navigation:** [README](../README.md) | [Usage](usage.md) | [Structure](structure.md) | [Secrets](secrets.md)

---

## NixOS Installation (Mothership)

### 1. Boot NixOS ISO

Download from [nixos.org](https://nixos.org/download.html) and boot.

### 2. Partition Drives

Mothership uses LUKS + ZFS on the main NVMe.

```bash
# Identify drives
lsblk

# Main NVMe (system)
DISK=/dev/nvme0n1

# Create partitions
parted $DISK -- mklabel gpt
parted $DISK -- mkpart ESP fat32 1MiB 512MiB
parted $DISK -- set 1 esp on
parted $DISK -- mkpart primary 512MiB 100%

# Format EFI
mkfs.fat -F 32 -n boot ${DISK}p1
```

### 3. Setup LUKS Encryption

```bash
# Create LUKS container
cryptsetup luksFormat ${DISK}p2
cryptsetup open ${DISK}p2 cryptroot

# Verify
ls /dev/mapper/cryptroot
```

### 4. Create ZFS Pool (rpool)

```bash
# Create pool on LUKS device
zpool create -f \
  -o ashift=12 \
  -O mountpoint=none \
  -O atime=off \
  -O compression=lz4 \
  -O xattr=sa \
  -O acltype=posixacl \
  rpool /dev/mapper/cryptroot

# System datasets
zfs create -o mountpoint=none rpool/nixos
zfs create -o mountpoint=legacy rpool/nixos/root
zfs create -o mountpoint=legacy rpool/nixos/nix
zfs create -o mountpoint=legacy -o encryption=on -o keyformat=passphrase rpool/nixos/home

# Container storage
zfs create -o mountpoint=legacy rpool/podman
zfs create -o mountpoint=legacy rpool/docker

# VM storage
zfs create -o mountpoint=none rpool/vm-pools

# Swap (optional, 16GB)
zfs create -V 16G -b $(getconf PAGESIZE) \
  -o compression=zle \
  -o logbias=throughput \
  -o sync=always \
  -o primarycache=metadata \
  -o secondarycache=none \
  rpool/swap
mkswap /dev/zvol/rpool/swap
```

### 5. Mount Filesystems

```bash
# Mount root
mount -t zfs rpool/nixos/root /mnt

# Create mount points
mkdir -p /mnt/{boot,nix,home,var/lib/containers,var/lib/docker}

# Mount all
mount ${DISK}p1 /mnt/boot
mount -t zfs rpool/nixos/nix /mnt/nix
mount -t zfs rpool/nixos/home /mnt/home
mount -t zfs rpool/podman /mnt/var/lib/containers
mount -t zfs rpool/docker /mnt/var/lib/docker

# Enable swap
swapon /dev/zvol/rpool/swap
```

### 6. Generate and Install

```bash
# Generate hardware config
nixos-generate-config --root /mnt

# Install minimal system
nixos-install
reboot
```

### 7. Clone and Bootstrap Config

```bash
# Clone repository
git clone https://github.com/szeigo/nixconfig ~/nixconfig
cd ~/nixconfig

# Decrypt secrets (prompts for passphrase)
make bootstrap

# Get machine's age key and add to .sops.yaml
nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'

# Re-encrypt secrets
make secrets-updatekeys

# Apply configuration
make switch HOST=mothership

# Clean up temporary keys
make cleanup
```

### 8. Additional Storage Pools (Optional)

#### fastPool (NVMe for MicroVMs, K3s PVCs)

```bash
zpool create -f \
  -o ashift=12 \
  -O mountpoint=/fastPool \
  -O compression=lz4 \
  fastPool /dev/nvme1n1

# MicroVM storage
zfs create -o mountpoint=/fastPool/microvm fastPool/microvm
zfs create -V 10G fastPool/microvm/k3s-worker-1
zfs create -V 10G fastPool/microvm/k3s-worker-2
zfs create -V 10G fastPool/microvm/k3s-worker-3

# K3s PVCs
zfs create fastPool/k3s
```

#### slowPool (HDD RAIDZ for bulk storage)

```bash
zpool create -f \
  -o ashift=12 \
  -O mountpoint=none \
  -O compression=lz4 \
  slowPool raidz1 /dev/sda /dev/sdb /dev/sdc

# File storage
zfs create -o mountpoint=/mnt/files slowPool/files

# Game storage
zfs create -o mountpoint=none slowPool/game-storage
```

---

## Dataset Reference (Mothership)

### rpool (System - LUKS encrypted NVMe)

| Dataset | Mountpoint | Purpose |
|---------|------------|---------|
| `rpool/nixos/root` | `/` | Root filesystem |
| `rpool/nixos/nix` | `/nix` | Nix store |
| `rpool/nixos/home` | `/home` | Home (ZFS encrypted) |
| `rpool/podman` | `/var/lib/containers` | Podman storage |
| `rpool/docker` | `/var/lib/docker` | Docker storage |
| `rpool/swap` | zvol | Swap space |
| `rpool/vm-pools/*` | zvol | VM disk images |

### fastPool (Fast NVMe)

| Dataset | Purpose |
|---------|---------|
| `fastPool/microvm/*` | MicroVM zvols |
| `fastPool/k3s/*` | K3s persistent volumes |

### slowPool (HDD RAIDZ)

| Dataset | Mountpoint | Purpose |
|---------|------------|---------|
| `slowPool/files` | `/mnt/files` | General storage |
| `slowPool/game-storage/*` | zvol | Game images |
| `slowPool/k3s/*` | legacy | K3s persistent volumes |

---

## macOS Installation

### 1. Install Nix

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Restart terminal.

### 2. Clone and Apply

```bash
git clone https://github.com/YOUR_USER/nixconfig ~/nixconfig
cd ~/nixconfig

# First run (bootstraps nix-darwin)
nix run nix-darwin -- switch --flake .#jsz-mac-01
```

### 3. Verify

Open new terminal. You should have:
- Powerlevel10k prompt
- All CLI tools (eza, bat, ripgrep, kubectl, k9s, etc.)
- Kitty terminal
- Helix editor

---

## Adding a New Host

### NixOS

1. Create host directory:
```bash
mkdir -p hosts/newhostname
```

2. Create `hosts/newhostname/configuration.nix`:
```nix
{ config, lib, pkgs, ... }: {
  imports = [
    ../../modules/common/users.nix
    ../../modules/common/zsh.nix
  ];
  networking.hostName = "newhostname";
  networking.hostId = "xxxxxxxx";  # head -c 8 /etc/machine-id
  system.stateVersion = "25.11";
}
```

3. Generate hardware config:
```bash
nixos-generate-config --show-hardware-config > hosts/newhostname/hardware.nix
```

4. Add to `flake.nix` (see existing mothership entry as template)

5. Add machine key to `.sops.yaml` and re-encrypt:
```bash
make secrets-updatekeys
make switch HOST=newhostname
```

---

**Next:** [Daily Usage](usage.md) | [ZFS Details](zfs.md)
