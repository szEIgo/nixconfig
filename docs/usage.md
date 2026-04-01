# Daily Usage

Common operations for managing NixOS and this configuration.

**Navigation:** [README](../README.md) | [Getting Started](getting-started.md) | [Structure](structure.md) | [Secrets](secrets.md)

---

## Fleet Deployment (deploy-rs)

Deploy configuration changes to fleet nodes with automatic rollback:

```bash
# Deploy to a single node
make deploy HOST=carrier-tc1

# Deploy to all fleet nodes
make deploy-all

# Fresh install (nixos-anywhere, wipes disk)
make deploy-new HOST=carrier-tc1 IP=192.168.2.192
```

If the node loses connectivity after activation, deploy-rs automatically
reverts to the previous generation.

---

## NixOS Operations

### Apply Configuration (local)

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
```

### Memory Control (Large Rebuilds)

```bash
NIX_JOBS=2 NIX_CORES=4 make switch
```

---

## macOS (nix-darwin)

```bash
# Apply changes
darwin-rebuild switch --flake .#jsz-mac-01

# Update and rebuild
nix flake update
darwin-rebuild switch --flake .#jsz-mac-01
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
make zfs-status

# Detailed
zpool status
zfs list -o name,used,avail,mountpoint
```

### Maintenance

```bash
make zfs-scrub
make zfs-snapshot DATASET=rpool/nixos/home
zfs list -t snapshot
```

---

## Virtual Machines (libvirt)

### VM Management

```bash
make vm-list
make vm-start VM=win11-nvidia
make vm-stop VM=win11-nvidia
make vm-console VM=win11-nvidia
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
make vm-fix-efi VM=win11-nvidia
```

---

## Kubernetes (k3s)

### Cluster Status

```bash
make k3s-status
kubectl get nodes
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

On client hosts (t480, etc.) — not mothership (which is the server):

```bash
make wg-connect
make wg-disconnect
make wg-status
```

| Host | WireGuard IP | Role |
|------|-------------|------|
| mothership | 192.168.10.1 | Server (port 51821) |
| t480 | 192.168.10.5 | Client |

---

## Secrets

```bash
# Edit encrypted secrets.yaml
make secrets-edit

# Re-encrypt for all hosts
make secrets-updatekeys

# After editing, clean up temporary keys
make cleanup
```

### Add New Machine

1. Get machine's age key:
```bash
nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'
```
2. Add to `.sops.yaml`
3. Re-encrypt: `make secrets-updatekeys`

---

## Troubleshooting

### Build Fails with OOM
```bash
NIX_JOBS=1 NIX_CORES=4 make switch
```

### Secrets Not Decrypting
```bash
systemctl status sops-nix
ls -la /etc/ssh/ssh_host_ed25519_key
```

### ZFS Pool Won't Import
```bash
zpool import -f poolname
zpool status -v
```

### Deploy-rs Fails
```bash
# Check SSH connectivity
ssh root@<ip> echo ok

# Check ssh-agent
ssh-add -l

# Manual deploy with verbose output
nix run github:serokell/deploy-rs -- .#carrier-tc1 -- --debug-logs
```

---

**See also:** [ZFS Details](zfs.md) | [Virtualization](virtualization.md) | [Secrets](secrets.md)
