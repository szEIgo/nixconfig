# NixConfig

Multi-platform Nix configuration for NixOS (mothership) and macOS (jsz-mac-01).

## Quick Reference

```bash
make help                    # Show all commands
make switch                  # Apply NixOS configuration
make update                  # Update flake inputs and rebuild
make gc                      # Garbage collect (default: 30 days)
```

## Documentation

| Doc | Description |
|-----|-------------|
| [Getting Started](docs/getting-started.md) | Fresh install guide |
| [Daily Usage](docs/usage.md) | Common operations |
| [Structure](docs/structure.md) | Repository layout |
| [Secrets](docs/secrets.md) | SOPS-nix setup |
| [ZFS](docs/zfs.md) | Storage management |
| [Virtualization](docs/virtualization.md) | VMs, MicroVMs, K3s |
| [macOS](docs/darwin.md) | nix-darwin setup |
| [Bootstrap](docs/bootstrap.md) | New machine setup |

## Hosts

| Host | Platform | Type | Description |
|------|----------|------|-------------|
| `mothership` | NixOS x86_64 | Desktop | Main workstation with GPU passthrough |
| `jsz-mac-01` | macOS aarch64 | Workstation | MacBook with nix-darwin |

## System Overview

```
mothership (NixOS)
├── Desktop: Hyprland / KDE Plasma 6
├── GPU: VFIO passthrough (NVIDIA + AMD)
├── Storage: ZFS (rpool, slowPool, fastPool)
├── K3s: Kubernetes control plane
├── MicroVMs: k3s workers (10.100.0.11-13)
└── VMs: Windows 11, Arch Linux (libvirt)

jsz-mac-01 (macOS)
├── Nix: CLI tools, dev environment
├── Homebrew: GUI apps (managed by nix-darwin)
└── Shared: Shell config, helix, kitty
```

## Command Categories

### NixOS Operations
```bash
make switch [HOST=...]       # Build and switch
make build [HOST=...]        # Build only
make test [HOST=...]         # Test without bootloader
make update [HOST=...]       # Update inputs + rebuild
make gc [DAYS=30]            # Garbage collect
```

### Secrets
```bash
make secrets-edit            # Edit secrets.yaml
make secrets-updatekeys      # Re-encrypt for all hosts
make bootstrap               # Decrypt master key (new machine)
make cleanup                 # Remove temporary keys
```

### Storage (ZFS)
```bash
make mount                   # Import and decrypt pools
make zfs-status              # Pool and dataset status
make zfs-scrub               # Start integrity scrub
make zfs-snapshot DATASET=.. # Create snapshot
```

### Virtualization
```bash
make vm-list                 # List all libvirt VMs
make vm-start VM=...         # Start VM
make vm-stop VM=...          # Stop VM
make vm-console VM=...       # Open VM console
make gpu-reset               # Reset AMD GPU
make usb-attach VM=...       # Attach USB to VM
```

### MicroVMs
```bash
make microvm-list            # List MicroVMs
make microvm-start [VM=...]  # Start VMs
make microvm-stop VM=...     # Stop VM
make microvm-ssh VM=...      # SSH via VSOCK
make microvm-init-zfs        # Create ZFS volumes
```

### Kubernetes (K3s)
```bash
make k3s-init                # Setup kubeconfig
make k3s-status              # Cluster status
make k3s-flux-bootstrap      # Install Flux CD
make k3s-flux-status         # Flux status
```

## Directory Structure

```
nixconfig/
├── flake.nix                # Entry point
├── Makefile                 # All operations
├── hosts/                   # Machine configs
│   ├── mothership/          # NixOS desktop
│   └── macbook/             # macOS
├── modules/                 # Reusable NixOS modules
│   ├── core/                # Required for all hosts
│   ├── common/              # Desktop extensions
│   ├── desktop/             # Hyprland, Plasma
│   └── virtualization/      # VMs, k3s, podman
├── home/                    # Home-manager (all platforms)
│   ├── joni.nix             # Main user config
│   ├── shell/               # Zsh config
│   └── profiles/            # Composable profiles
├── secrets/                 # SOPS-encrypted secrets
├── scripts/                 # Management scripts
└── docs/                    # Documentation
```

## License

Personal configuration - use at your own risk.
