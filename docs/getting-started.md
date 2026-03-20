# Getting Started

Fresh system setup from zero to running.

**Navigation:** [README](../README.md) | [Usage](usage.md) | [Structure](structure.md) | [Secrets](secrets.md)

---

## NixOS Installation

### 1. Boot NixOS ISO

Download from [nixos.org](https://nixos.org/download.html) and boot.

### 2. Partition and Install Base System

```bash
# Partition (adjust for your drives)
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 512MiB 100%

# Format
mkfs.fat -F 32 -n boot /dev/nvme0n1p1

# For ZFS root (recommended)
zpool create -O mountpoint=none -O atime=off -O compression=lz4 rpool /dev/nvme0n1p2
zfs create -o mountpoint=legacy rpool/nixos/root
zfs create -o mountpoint=legacy rpool/nixos/nix
zfs create -o mountpoint=legacy rpool/nixos/home

# Mount
mount -t zfs rpool/nixos/root /mnt
mkdir -p /mnt/{boot,nix,home}
mount /dev/nvme0n1p1 /mnt/boot
mount -t zfs rpool/nixos/nix /mnt/nix
mount -t zfs rpool/nixos/home /mnt/home

# Generate config
nixos-generate-config --root /mnt

# Install minimal system
nixos-install
reboot
```

### 3. Clone and Bootstrap This Config

```bash
# Clone repository
git clone https://github.com/YOUR_USER/nixconfig ~/nixconfig
cd ~/nixconfig

# Decrypt secrets (prompts for passphrase)
make bootstrap

# Get machine's age key
nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'
# Add this key to .sops.yaml

# Re-encrypt secrets for this machine
make secrets-updatekeys

# Apply configuration
make switch HOST=mothership

# Clean up temporary keys
make cleanup
```

### 4. Post-Install

```bash
# Import ZFS pools (if using additional pools)
make mount

# Start k3s cluster (optional)
make k3s-init
```

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

4. Add to `flake.nix`:
```nix
nixosConfigurations = {
  newhostname = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./modules/core
      ./hosts/newhostname/configuration.nix
      ./hosts/newhostname/hardware.nix
      # ... rest of modules
    ];
  };
};
```

5. Add machine key to `.sops.yaml` and re-encrypt:
```bash
make secrets-updatekeys
make switch HOST=newhostname
```

---

**Next:** [Daily Usage](usage.md)
