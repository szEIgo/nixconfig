# Repository Structure

Multi-platform NixOS configuration supporting desktops, servers, and macOS.

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
│   ├── hyprland.nix          # Hyprland window manager
│   ├── plasma6.nix           # KDE Plasma config
│   ├── omarchy-theme.nix     # GTK/cursor/kitty theming
│   ├── fonts.nix             # Font packages
│   └── configs/              # Dotfiles
│       ├── gitconfig
│       ├── p10k.zsh
│       └── plasma6/
│
├── hosts/                    # Machine-specific configs
│   └── mothership/
│       ├── configuration.nix # Main NixOS config
│       ├── hardware.nix      # Generated hardware config
│       ├── packages.nix      # Host-specific packages
│       └── devices/          # Hardware variants
│
├── modules/                  # Reusable NixOS modules
│   ├── core/                 # Required for ALL NixOS hosts
│   │   ├── default.nix       # Imports all core modules
│   │   ├── nix-settings.nix  # Flakes, gc, store optimization
│   │   ├── locales.nix       # Timezone, locale, keyboard
│   │   └── users.nix         # Basic user (wheel group)
│   ├── common/               # Desktop extensions
│   │   ├── users.nix         # Adds libvirtd, kvm, podman groups
│   │   ├── zsh.nix           # System zsh (root prompt)
│   │   ├── packages.nix      # System packages
│   │   ├── services.nix      # Display manager, logind
│   │   └── zfs.nix           # ZFS support
│   ├── desktop/
│   │   ├── hyprland.nix      # Hyprland + Wayland
│   │   └── plasma.nix        # KDE Plasma 6
│   ├── gaming/
│   │   └── steam.nix         # Steam + gamemode
│   └── virtualization/
│       ├── k3s.nix           # Kubernetes
│       ├── libvirt.nix       # KVM/QEMU
│       └── podman.nix        # Containers
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
- `zsh.nix` - System-level zsh with root prompt
- `packages.nix` - System packages
- `services.nix` - SDDM, logind settings

### Virtualization (modules/virtualization/)
Container and VM support:
- `k3s.nix` - Lightweight Kubernetes
- `libvirt.nix` - KVM/QEMU with VFIO hooks
- `podman.nix` - Docker-compatible containers

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
