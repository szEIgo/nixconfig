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
│   │   ├── configuration.nix # Main NixOS config (desktop, k3s server, ZFS)
│   │   ├── hardware.nix      # Generated hardware config
│   │   ├── packages.nix      # Host-specific packages
│   │   └── devices/          # Hardware variants, network, wireguard
│   ├── t480/
│   │   ├── configuration.nix # Laptop config (Plasma, TLP, WiFi)
│   │   └── hardware.nix      # ThinkPad T480 hardware
│   ├── worker/               # Shared config for all k3s fleet nodes
│   │   ├── configuration.nix # k3s config (role, labels, firewall, role-guard)
│   │   ├── hardware.nix      # Shared hardware (Intel, SATA SSD)
│   │   ├── disko.nix         # Declarative disk layout + node options
│   │   └── iso.nix           # Custom installer ISO (sshd + SSH keys)
│   ├── x250/                 # ThinkPad X250 laptop
│   ├── android/              # nix-on-droid (shell + CLI tools)
│   └── macbook/              # nix-darwin for macOS
│
├── modules/                  # Reusable NixOS modules
│   ├── core/                 # Required for ALL NixOS hosts
│   │   ├── default.nix       # Imports all core modules
│   │   ├── nix-settings.nix  # Flakes, gc, store optimization
│   │   ├── locales.nix       # Timezone, locale, keyboard
│   │   └── users.nix         # Basic user (wheel group)
│   ├── common/               # Shared extensions
│   │   ├── users.nix         # Adds libvirtd, kvm, podman groups
│   │   ├── zsh.nix           # System-wide zsh (all users incl. root)
│   │   ├── packages.nix      # System packages
│   │   ├── services.nix      # Display manager, logind
│   │   ├── nfs-server.nix    # NFS exports for k3s cluster
│   │   └── zfs.nix           # ZFS support
│   ├── desktop/
│   │   ├── hyprland.nix      # Hyprland + Wayland
│   │   └── plasma.nix        # KDE Plasma 6
│   ├── gaming/
│   │   └── steam.nix         # Steam + gamemode
│   └── virtualization/
│       ├── k3s.nix           # k3s control plane (HA, embedded etcd)
│       ├── libvirt.nix       # KVM/QEMU with VFIO
│       ├── podman.nix        # Containers
│       ├── vms/              # Declarative libvirt VMs (NixVirt)
│       │   ├── default.nix   # VM domain definitions
│       │   └── xml/          # Libvirt XML configs
│       └── microvm/          # Lightweight k3s VMs (disabled)
│           ├── default.nix   # Host config, bridge, ZFS
│           └── k3s-agent.nix # Guest k3s agent
│
├── remote/                   # Remote access
│   ├── ssh.nix               # SSH server, ssh-agent systemd service
│   └── remote-desktop.nix
│
├── secrets/                  # sops-nix encrypted secrets
│   ├── secrets.yaml          # Encrypted secrets (safe for git)
│   ├── secrets.nix           # Mothership secret paths
│   └── worker.nix            # Fleet node secret paths (k3s token)
│
├── scripts/                  # Management scripts
│   ├── nixos/                # switch, build, test, update, gc
│   ├── k3s/                  # status, wipe, flux-*
│   ├── storage/              # mount-pools, zfs-status, scrub, snapshot
│   ├── hardware/             # gpu-reset, usb-attach
│   ├── vm/                   # list, start, stop, console, fix-efi, vnc
│   ├── secrets/              # edit, updatekeys, list
│   ├── bootstrap/            # deploy-worker, decrypt-keys, cleanup
│   └── wireguard/            # connect, disconnect, status
│
└── docs/                     # Documentation
```

## k3s Cluster Architecture

StarCraft Protoss fleet naming: mothership (command), carriers (control plane), interceptors (workers).

```
k3s HA Cluster (3 control plane nodes, embedded etcd)
│
├── Control Plane (k3s servers):
│   ├── mothership       (192.168.2.62)  — 32c/32GB, ZFS storage, initial server
│   ├── carrier-tc1      (192.168.2.192) — 8c/16GB ThinkCentre
│   └── carrier-tc2      (192.168.2.250) — 4c/8GB ThinkCentre
│
└── Workers (k3s agents):
    ├── interceptor-nuc1 (192.168.2.102) — 4c/8GB Intel NUC
    ├── interceptor-tc1  (192.168.2.238) — 4c/6GB ThinkCentre
    └── interceptor-tc2  (192.168.2.147) — 4c/4GB ThinkCentre
```

**Node overview:**

| Node | Role | CPUs | RAM | Size Label | IP |
|------|------|------|-----|------------|----|
| mothership | control-plane | 32 | 32 GB | `large` | 192.168.2.62 |
| carrier-tc1 | control-plane | 8 | 16 GB | `medium` | 192.168.2.192 |
| carrier-tc2 | control-plane | 4 | 8 GB | `medium` | 192.168.2.250 |
| interceptor-nuc1 | worker | 4 | 8 GB | `medium` | 192.168.2.102 |
| interceptor-tc1 | worker | 4 | 6 GB | `small` | 192.168.2.238 |
| interceptor-tc2 | worker | 4 | 4 GB | `small` | 192.168.2.147 |

Fleet nodes are defined via `mkWorker` in `flake.nix` with shared config from `hosts/worker/`. Each node gets:
- `k3sRole`: `"server"` (carrier) or `"agent"` (interceptor)
- `nodeSize`: `"small"`, `"medium"`, or `"large"` (scheduling label)
- `bootMode`: `"legacy"` (BIOS/GRUB) or `"uefi"` (systemd-boot)

**Node labels:** All nodes get `node-id=<hostname>` and `node.kubernetes.io/size=<small|medium|large>`. Control plane nodes additionally get `node-role.kubernetes.io/control-plane=true` (set automatically by k3s).

**Scheduling with labels:**
```yaml
# Target medium or large nodes
nodeSelector:
  node.kubernetes.io/size: medium

# Target a specific node
nodeSelector:
  node-id: mothership
```

**Storage:** OpenEBS ZFS CSI on mothership (fastPool/slowPool). Democratic CSI NFS from mothership at 192.168.2.62.

**Deployment:**
- `make deploy HOST=<node>` — deploy config updates via deploy-rs (automatic rollback)
- `make deploy-all` — deploy to all fleet nodes
- `make deploy-new HOST=<node> IP=<ip>` — fresh install via nixos-anywhere

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

## Home-Manager Profiles

Profiles are composed based on `hostType` passed from flake.nix:

| hostType | Profiles | Use Case |
|----------|----------|----------|
| `"server"` | base | Headless servers |
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

### New Fleet Node
1. Boot the worker ISO on the target machine
2. From mothership: `make deploy-new HOST=<name> IP=<ip>`
3. Add to `flake.nix` via `mkWorker` and to `deploy.nodes`
4. Future updates: `make deploy HOST=<name>`

### New Module
1. Create `modules/category/mymodule.nix`
2. Import in host configuration or add to a profile

### New Home-Manager Program
1. Add to appropriate profile in `home/profiles/`
2. Or create new profile and import in `home/joni.nix`

## Command Reference

Run `make help` for full details. Key commands:

### Deployment
| Command | Description |
|---------|-------------|
| `make deploy HOST=...` | Deploy to a node via deploy-rs (with rollback) |
| `make deploy-all` | Deploy to all fleet nodes |
| `make deploy-new HOST=... IP=...` | Fresh install via nixos-anywhere |

### NixOS
| Command | Description |
|---------|-------------|
| `make switch` | Build and switch to configuration |
| `make build` | Build without switching |
| `make update` | Update flake inputs and rebuild |
| `make gc` | Garbage collect old generations |

### Kubernetes (k3s)
| Command | Description |
|---------|-------------|
| `make k3s-status` | Show nodes, pods, services |
| `make k3s-wipe` | Wipe k3s state |
| `make k3s-flux-bootstrap` | Bootstrap Flux CD |
| `make k3s-flux-status` | Show Flux sources and kustomizations |

### Storage & VMs
| Command | Description |
|---------|-------------|
| `make mount` | Import and decrypt ZFS pools |
| `make vm-start VM=...` | Start a libvirt VM |
| `make vm-stop VM=...` | Graceful shutdown |

### Secrets & Hardware
| Command | Description |
|---------|-------------|
| `make secrets-edit` | Edit encrypted secrets |
| `make gpu-reset` | Reset AMD GPU (PCI rescan) |
