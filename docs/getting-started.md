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
```

ZFS requires `networking.hostId` to be set before `nixos-install` will succeed.
Add it to the generated config:

```bash
# Generate a random 8-char hex hostId
head -c4 /dev/urandom | od -A none -t x4 | tr -d ' '

# Add to the generated configuration
vim /mnt/etc/nixos/configuration.nix
# → Add: networking.hostId = "<hex string from above>";
```

Then install and reboot:

```bash
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

### 1. Install NixOS

- **Headless machines** (servers, NUCs): See [Headless Getting Started](headless-getting-started.md)
- **Laptops/desktops**: Use the NixOS graphical installer, or boot the minimal ISO and run `make install`

### 2. Create host config

```bash
mkdir -p hosts/<hostname>
```

Create `configuration.nix` and `hardware.nix` — see existing hosts as templates:
- **Desktop laptop**: `hosts/t480/` or `hosts/x250/` (Plasma, TLP, NetworkManager)
- **Headless server**: `hosts/nuc/` (k3s worker, no desktop)
- **Workstation**: `hosts/mothership/` (GPU passthrough, virtualization)

### 3. Get real hardware config

SSH into the new host and generate the hardware config:

```bash
ssh joni@<ip>
nixos-generate-config --show-hardware-config
```

Copy the output into `hosts/<hostname>/hardware.nix`, keeping any custom additions
(network.nix import, `i915` in initrd for Intel laptops, etc).

### 4. Add to flake.nix

Add a `nixosConfigurations.<hostname>` entry (copy an existing one as template).
Stage the new files so Nix can see them:

```bash
git add hosts/<hostname>/
```

Verify it evaluates:

```bash
nix eval .#nixosConfigurations.<hostname>.config.networking.hostName
```

### 5. First switch

SSH into the new host, clone the repo, and apply:

```bash
ssh joni@<ip>
nix-shell -p git
git clone https://github.com/szeigo/nixconfig ~/nixconfig
cd ~/nixconfig
make switch HOST=<hostname>
```

### 6. Add SSH keys

From any machine that can reach the new host:

```bash
make add-host-keys HOST=<hostname> IP=<ip>
```

This will:
- Generate an SSH key pair on the host
- Encrypt the private key in SOPS (`secrets/secrets.yaml`)
- Add the public key to `remote/authorized_keys`
- Add the host's age key to `.sops.yaml`
- Create `secrets/<hostname>.nix`

Then add SOPS to the host's entry in `flake.nix`:

```nix
sops-nix.nixosModules.sops
./secrets/<hostname>.nix
```

### 7. Rebuild

Push and rebuild the new host to deploy SSH keys:

```bash
git add -A && git commit -m "Add <hostname>"
make switch HOST=<hostname>
```

Rebuild other hosts to pick up the new authorized key in `remote/authorized_keys`.

---

**Next:** [Daily Usage](usage.md) | [ZFS Details](zfs.md)
