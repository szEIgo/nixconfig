# Repository Structure

Multi-platform NixOS configuration supporting desktops, servers, and macOS.

**Navigation:** [README](../README.md) | [Getting Started](getting-started.md) | [Usage](usage.md) | [Virtualization](virtualization.md)

---

## Directory Layout

```
nixconfig/
├── flake.nix                 # Entry point, defines all hosts
├── flake.lock                # Pinned dependencies
├── .sops.yaml                # Secret encryption keys
│
├── home/                     # Home-manager (all platforms)
│   ├── joni.nix              # Main config, composes profiles
│   ├── profiles/             # Composable feature sets
│   │   ├── base.nix          # Core CLI tools (always included)
│   │   ├── dev.nix           # Development tools
│   │   └── desktop.nix       # Desktop/GUI applications
│   ├── shell/
│   │   └── default.nix       # Unified zsh configuration
│   ├── hyprland.nix          # Hyprland window manager + GTK theming
│   ├── plasma.nix            # KDE Plasma config (plasma-manager)
│   ├── fonts.nix             # Font packages
│   └── configs/              # Dotfiles
│       ├── gitconfig
│       ├── p10k.zsh
│       └── plasma6/
│
├── hosts/                    # Machine-specific configs
│   ├── mothership/
│   │   ├── configuration.nix # Main NixOS config
│   │   ├── hardware.nix      # Generated hardware config
│   │   ├── packages.nix      # Host-specific packages
│   │   └── devices/          # Hardware variants
│   ├── t480/
│   │   ├── configuration.nix # Laptop config (Plasma, TLP, WiFi)
│   │   └── hardware.nix      # ThinkPad T480 hardware
│   ├── nuc/
│   │   ├── configuration.nix # Headless k3s worker
│   │   └── hardware.nix      # Intel NUC hardware
│   ├── worker/               # Shared config for all k3s worker nodes
│   │   ├── configuration.nix # Worker NixOS config (k3s, firewall, zsh, ssh)
│   │   ├── hardware.nix      # Shared hardware (Intel, SATA SSD)
│   │   ├── disko.nix         # Declarative disk layout (GRUB + ext4)
│   │   └── iso.nix           # Custom installer ISO (sshd + SSH keys)
│   ├── android/
│   │   └── default.nix       # nix-on-droid config (shell + CLI tools)
│   └── macbook/
│
├── modules/                  # Reusable NixOS modules
│   ├── core/                 # Required for ALL NixOS hosts
│   │   ├── default.nix       # Imports all core modules
│   │   ├── nix-settings.nix  # Flakes, gc, store optimization
│   │   ├── locales.nix       # Timezone, locale, keyboard
│   │   └── users.nix         # Basic user (wheel group)
│   ├── common/               # Desktop extensions
│   │   ├── users.nix         # Adds libvirtd, kvm, podman groups
│   │   ├── zsh.nix           # System-wide zsh (oh-my-zsh, p10k, aliases for all users incl. root)
│   │   ├── packages.nix      # System packages
│   │   ├── services.nix      # Display manager, logind
│   │   └── zfs.nix           # ZFS support
│   ├── desktop/
│   │   ├── hyprland.nix      # Hyprland + Wayland
│   │   └── plasma.nix        # KDE Plasma 6
│   ├── gaming/
│   │   └── steam.nix         # Steam + gamemode
│   └── virtualization/
│       ├── k3s.nix           # Kubernetes control plane
│       ├── libvirt.nix       # KVM/QEMU with VFIO
│       ├── podman.nix        # Containers
│       ├── vms/              # Declarative libvirt VMs (NixVirt)
│       │   ├── default.nix   # VM domain definitions
│       │   └── xml/          # Libvirt XML configs
│       └── microvm/          # Lightweight k3s worker VMs
│           ├── default.nix   # Host config, bridge, ZFS
│           └── k3s-agent.nix # Guest k3s agent
│
├── darwin/                   # macOS (nix-darwin)
│   └── default.nix           # System defaults, homebrew
│
├── remote/                   # Remote access
│   ├── ssh.nix               # SSH server config
│   └── remote-desktop.nix
│
├── secrets/                  # sops-nix encrypted secrets
│   ├── secrets.yaml          # Encrypted secrets (safe for git)
│   ├── secrets.nix           # Deployment paths
│   └── *.age                 # Encrypted keys
│
├── scripts/                  # Management scripts
│   ├── nixos/                # switch, build, test, update, gc
│   ├── k3s/                  # init, wipe, status, flux-*
│   ├── microvm/              # list, status, start, stop, ssh, zfs
│   ├── storage/              # mount-pools (ZFS import/decrypt)
│   ├── hardware/             # gpu-reset, usb-attach
│   ├── vm/                   # fix-efi, vnc
│   ├── secrets/              # edit, updatekeys
│   └── bootstrap/            # decrypt-keys, cleanup, deploy-worker
│
└── docs/                     # Documentation
```

## Module Hierarchy

### Core (modules/core/)
Minimal base imported via `flake.nix` for ALL NixOS hosts:
- Nix flakes enabled
- Garbage collection
- Locale/timezone defaults
- Basic user with wheel group

### Common (modules/common/)
Extensions for desktop/workstation machines:
- `users.nix` - Adds groups: libvirtd, kvm, podman, video, seat
- `zsh.nix` - System-wide zsh (oh-my-zsh, powerlevel10k, aliases for all users including root)
- `packages.nix` - System packages
- `services.nix` - SDDM, logind settings

### Virtualization (modules/virtualization/)
Container and VM support:
- `k3s.nix` - Lightweight Kubernetes (control plane on mothership)
- `libvirt.nix` - KVM/QEMU with VFIO hooks, polkit rules, KSM
- `podman.nix` - Docker-compatible containers
- `vms/` - Declarative libvirt VMs via NixVirt (see below)
- `microvm/` - Lightweight VMs for k3s worker nodes (see below)

### MicroVM (modules/virtualization/microvm/)
Lightweight VMs using cloud-hypervisor for k3s worker nodes:
- `default.nix` - Host configuration, network bridge, ZFS storage
- `k3s-agent.nix` - Guest k3s agent configuration

**Architecture:**
```
mothership (k3s server, 192.168.2.62)
          │
          ├── Bare-metal workers (shared hosts/worker/ config, deployed via nixos-anywhere):
          │   ├── nuc    (192.168.2.102)
          │   ├── node5  (192.168.2.147)
          │   ├── node6  (192.168.2.192)
          │   ├── node9  (192.168.2.250)
          │   └── node12 (192.168.2.238)
          │
          └── MicroVM workers (10.100.0.0/24):
              ├── k3s-worker-1 (10.100.0.11)
              ├── k3s-worker-2 (10.100.0.12)
              └── k3s-worker-3 (10.100.0.13)
```

**Node labels:** All workers set `k3s.io/role=worker`. MicroVMs add `node-type=microvm` + `node-id=worker-{N}`. The nuc adds `node-type=bare-metal`, `node-id=nuc`, and `node-role=customer`.

**Storage:** MicroVM zvols at `fastPool/microvm/k3s-worker-{1,2,3}` mounted as `/var/lib/rancher`. Nuc uses local ext4 disk.

**Boot flow (manual, ZFS encrypted):**
1. `make mount` - Import and decrypt ZFS pools
2. `make microvm-start` - Copy k3s token, start VMs
3. Workers auto-join cluster

### NixVirt (modules/virtualization/vms/)
Declarative libvirt VM management using [NixVirt](https://github.com/AshleyYakeley/NixVirt).
VMs are defined in Nix and their libvirt XML configs are version-controlled.

**Configured VMs:**
| VM | Description |
|----|-------------|
| `win11-nvidia` | Windows 11 with NVIDIA GPU passthrough |
| `win11-amd` | Windows 11 with AMD GPU passthrough |
| `win11-goldenImage` | Windows 11 base/template image |
| `archlinux` | Arch Linux VM |

**Key features:**
- VMs are defined declaratively in `vms/default.nix`
- XML configs stored in `vms/xml/` for full control
- `active = null` means VMs don't auto-start (manual via `virsh start`)
- Changes to VM definitions apply on `nixos-rebuild switch`

**Usage:**
```bash
virsh list --all          # List all VMs
virsh start win11-nvidia  # Start a VM
virsh shutdown win11-amd  # Graceful shutdown
```

## Home-Manager Profiles

Profiles are composed based on `hostType` passed from flake.nix:

| hostType | Profiles | Use Case |
|----------|----------|----------|
| `"server"` | base | Headless servers, Pis |
| `"workstation"` | base + dev | Dev machines without GUI |
| `"desktop"` | base + dev + desktop | Full desktop |

### base.nix
Core CLI tools for all platforms:
- Shell: zsh, fzf, zoxide, eza, bat
- Editors: helix, neovim
- Tools: git, gh, ripgrep, jq, tmux, yazi

### dev.nix
Development tools:
- Kubernetes: kubectl, k9s, kustomize, fluxcd
- Languages: rust, scala, jdk
- Infrastructure: sops, age, wireguard-tools

### desktop.nix
Desktop applications:
- Browser: firefox
- Theming: catppuccin, papirus icons
- Window managers: hyprland, plasma6 configs
- Fonts

## Adding Components

### New Host
See [bootstrap.md](bootstrap.md#adding-a-new-host)

### New Module
1. Create `modules/category/mymodule.nix`
2. Import in host configuration or add to a profile

### New Home-Manager Program
1. Add to appropriate profile in `home/profiles/`
2. Or create new profile and import in `home/joni.nix`

## Platform Support

| Platform | System | Type |
|----------|--------|------|
| NixOS x86_64 | `x86_64-linux` | Full system |
| NixOS ARM64 | `aarch64-linux` | Full system (Pi) |
| macOS | `aarch64-darwin` | home-manager or nix-darwin |

## Command Reference

Run `make help` for full details. Key commands:

### NixOS
| Command | Description |
|---------|-------------|
| `make switch` | Build and switch to configuration |
| `make build` | Build without switching |
| `make update` | Update flake inputs and rebuild |
| `make gc` | Garbage collect old generations |

### Storage & MicroVM
| Command | Description |
|---------|-------------|
| `make mount` | Import and decrypt ZFS pools |
| `make microvm-start` | Copy k3s token and start all VMs |
| `make microvm-stop VM=...` | Stop specific or all VMs |
| `make microvm-status` | Show VM status |
| `make microvm-ssh VM=...` | SSH into VM via VSOCK |
| `make microvm-init-zfs` | Create ZFS zvols for VMs |

### Kubernetes (k3s)
| Command | Description |
|---------|-------------|
| `make k3s-init` | Copy kubeconfig to ~/.kube/config |
| `make k3s-status` | Show nodes, pods, services |
| `make k3s-wipe` | Wipe k3s state |
| `make k3s-flux-bootstrap` | Bootstrap Flux CD |
| `make k3s-flux-status` | Show Flux sources and kustomizations |

### Libvirt VMs (NixVirt)
| Command | Description |
|---------|-------------|
| `virsh list --all` | List all defined VMs |
| `virsh start <vm>` | Start a VM |
| `virsh shutdown <vm>` | Graceful shutdown |
| `make vm-fix-efi VM=...` | Remove EFI entries from VM |
| `make usb-attach VM=...` | Attach USB devices to VM |
| `make vnc` | Start headless KDE with VNC |

### Secrets & Hardware
| Command | Description |
|---------|-------------|
| `make secrets-edit` | Edit encrypted secrets |
| `make gpu-reset` | Reset AMD GPU (PCI rescan) |
