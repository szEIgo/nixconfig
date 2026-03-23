# Daily Usage

Common operations for managing NixOS and this configuration.

**Navigation:** [README](../README.md) | [Getting Started](getting-started.md) | [Structure](structure.md) | [Secrets](secrets.md)

---

## NixOS Operations

### Apply Configuration

```bash
# Build and switch (default: current hostname)
make switch

# Specific host
make switch HOST=mothership

# Build without switching (test compilation)
make build

# Test without adding bootloader entry
make test
```

### Update System

```bash
# Update all flake inputs and rebuild
make update

# Just update inputs (no rebuild)
nix flake update
```

### Garbage Collection

```bash
# Remove generations older than 30 days
make gc

# Custom retention
make gc DAYS=7

# Manual: list generations
nix-env --list-generations

# Manual: delete specific generation
nix-env --delete-generations 42
```

### Memory Control (Large Rebuilds)

```bash
# Reduce parallel builds and cores
NIX_JOBS=2 NIX_CORES=4 make switch

# Limit evaluator heap
GC_INITIAL_HEAP_SIZE=4294967296 make switch  # 4GB
```

---

## macOS (nix-darwin)

```bash
# Apply changes
darwin-rebuild switch --flake .#jsz-mac-01

# Update and rebuild
nix flake update
darwin-rebuild switch --flake .#jsz-mac-01

# Garbage collect
nix-collect-garbage -d
```

---

## Storage (ZFS)

### After Reboot

```bash
# Import and decrypt pools
make mount
```

### Status

```bash
# Pool and dataset overview
make zfs-status

# Detailed pool info
zpool status
zfs list -o name,used,avail,mountpoint
```

### Maintenance

```bash
# Start integrity scrub
make zfs-scrub

# Create snapshot
make zfs-snapshot DATASET=rpool/nixos/home

# List snapshots
zfs list -t snapshot
```

---

## Virtual Machines (libvirt)

### VM Management

```bash
# List all VMs
make vm-list

# Start/stop VM
make vm-start VM=win11-nvidia
make vm-stop VM=win11-nvidia

# Console access
make vm-console VM=win11-nvidia

# Force stop
virsh destroy win11-nvidia
```

### GPU Passthrough

```bash
# Reset AMD GPU after VM shutdown
make gpu-reset

# Attach USB device to VM
make usb-attach VM=win11-nvidia
```

### EFI Issues

```bash
# Remove stale EFI entries
make vm-fix-efi VM=win11-nvidia
```

---

## MicroVMs (k3s workers)

### Boot Flow

After reboot with encrypted ZFS:

```bash
# 1. Import and decrypt pools
make mount

# 2. Start all MicroVMs
make microvm-start
```

### Management

```bash
# List VMs and status
make microvm-list
make microvm-status

# Start/stop specific VM
make microvm-start VM=k3s-worker-1
make microvm-stop VM=k3s-worker-1

# SSH into VM
make microvm-ssh VM=k3s-worker-1

# Restart all
make microvm-restart VM=all
```

### Storage

```bash
# Initialize ZFS volumes (first time)
make microvm-init-zfs

# Resize volume
make microvm-resize ID=1 SIZE=20G
```

---

## Kubernetes (k3s)

### Initial Setup

```bash
# Copy kubeconfig to ~/.kube/config
make k3s-init
```

### Cluster Status

```bash
make k3s-status
```

### Flux CD

```bash
# Bootstrap Flux
make k3s-flux-bootstrap

# Status
make k3s-flux-status

# Force reconcile
make k3s-flux-reconcile
make k3s-flux-reconcile TARGET=flux-system
```

### Wipe Cluster

```bash
# Stop and reset k3s
make k3s-wipe

# Wipe and prevent restart
make k3s-wipe ARGS=--mask
```

---

## WireGuard VPN

### Connect / Disconnect

On any client host (t480, nuc, etc.) — not mothership (which is the server):

```bash
# Connect to mothership VPN
make wg-connect

# Disconnect
make wg-disconnect

# Check status (works on all hosts including mothership)
make wg-status
```

### Network

| Host | WireGuard IP | Role |
|------|-------------|------|
| mothership | 192.168.10.1 | Server (port 51821) |
| t480 | 192.168.10.5 | Client |

### Adding WireGuard to a New Host

1. Generate a keypair: `wg genkey | tee private.key | wg pubkey > public.key`
2. Add the private key to sops: `make secrets-edit`
3. Add a `wireguard.nix` to the host (see `hosts/t480/wireguard.nix` as template)
4. Add the host's secret deployment in `secrets/<host>.nix`
5. Add the host as a peer in `hosts/mothership/devices/wireguard-server.nix`
6. Rebuild mothership: `make switch`
7. Delete the plaintext keys

---

## Secrets

### Edit Secrets

```bash
# Edit encrypted secrets.yaml
make secrets-edit

# After editing, clean up temporary keys
make cleanup
```

### Add New Machine

1. Get machine's age key:
```bash
nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'
```

2. Add to `.sops.yaml`

3. Re-encrypt:
```bash
make secrets-updatekeys
```

---

## Troubleshooting

### Build Fails with OOM

```bash
NIX_JOBS=1 NIX_CORES=4 make switch
```

### Secrets Not Decrypting

```bash
# Check sops-nix service
systemctl status sops-nix

# Verify SSH key exists
ls -la /etc/ssh/ssh_host_ed25519_key
```

### ZFS Pool Won't Import

```bash
# Force import (recovery mode)
zpool import -f poolname

# Check pool status
zpool status -v
```

### VM Won't Start

```bash
# Check libvirt logs
journalctl -u libvirtd -f

# Verify VFIO bindings
lspci -nnk | grep -A3 NVIDIA
```

---

**See also:** [ZFS Details](zfs.md) | [Virtualization](virtualization.md) | [Secrets](secrets.md)
