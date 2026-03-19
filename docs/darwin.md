# macOS (nix-darwin) Setup Guide

How to set up and use this Nix configuration on a Mac.

## Prerequisites

- macOS on Apple Silicon (aarch64-darwin)
- Admin access (for initial install)

## Initial Setup

### 1. Install Nix

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Restart your terminal after installation.

### 2. Clone the repository

```bash
git clone https://github.com/YOUR_USER/nixconfig ~/IdeaProjects/szeigo/nixconfig
cd ~/IdeaProjects/szeigo/nixconfig
```

### 3. First build

On the very first run, nix-darwin isn't installed yet, so bootstrap it via the flake:

```bash
nix run nix-darwin -- switch --flake .#jsz-mac-01
```

This will:
- Install nix-darwin system-wide
- Set up home-manager (zsh, helix, kitty, git, fonts, etc.)
- Configure macOS system defaults (dock, finder, trackpad)
- Declaratively manage Homebrew casks and formulae

You may be prompted for your password during the first run.

### 4. Verify

Open a new terminal. You should have:
- Powerlevel10k prompt
- All shared CLI tools (eza, bat, ripgrep, fzf, k9s, kubectl, etc.)
- Kitty terminal with OneHalfDark theme
- Zellij terminal multiplexer
- Helix editor

## Day-to-Day Usage

### Applying changes

After editing the nix config:

```bash
darwin-rebuild switch --flake .#jsz-mac-01
```

### Updating nixpkgs

```bash
nix flake update
darwin-rebuild switch --flake .#jsz-mac-01
```

### Listing installed packages

Nix-managed:
```bash
nix profile list   # home-manager packages
brew list           # declarative Homebrew packages (managed by nix-darwin)
```

### Garbage collection

Remove old generations and free disk space:

```bash
nix-collect-garbage -d
```

## What's Managed Where

### Nix (cross-platform, shared with NixOS mothership)

All CLI tools and dev environment — declared in `home/joni.nix`:

| Category | Packages |
|----------|----------|
| Core CLI | eza, bat, ripgrep, fd, jq, yq, htop, btop, ncdu, tree, dust, tldr, glow, watch |
| Shell | zsh, powerlevel10k, oh-my-zsh, zellij, fzf, zoxide |
| Editors | helix, neovim, vim |
| Dev | gnumake, gh, glab, sops, age, gnupg |
| Languages | rust (rustc, cargo, rustfmt), scala, sbt, pnpm, uv, jdk |
| DevOps | kubectl, kustomize, fluxcd, k9s, helm, cosign, opentofu, pulumi |
| Misc | graphviz, plantuml, mc, yamllint, sshpass, yazi, nmap, speedtest-cli |

Shell config (aliases, keybindings, ssh agent, etc.) is in `home/zsh.nix`.

### Homebrew casks (macOS GUI apps, declared in `hosts/macbook/default.nix`)

Managed declaratively by nix-darwin — `homebrew.onActivation.cleanup = "zap"` means
**any cask not listed in the config will be removed** on `darwin-rebuild switch`.

To add a new GUI app, add it to the `casks` list in `hosts/macbook/default.nix` and rebuild.

### Homebrew formulae (macOS-only CLI tools without good nixpkgs equivalents)

cocoapods, docker-buildx, docker-compose, gitlab-runner, k3d, pipx, rbenv, ruby-build

### Not managed (manual installs)

- SDKMAN (JVM SDKs) — sourced in zshrc, installed independently
- Bun — installed independently, sourced in zshrc on macOS
- Cargo crates — managed via `cargo install`

## Architecture

```
flake.nix
├── darwinConfigurations."jsz-mac-01"    ← this Mac
│   ├── hosts/macbook/default.nix        ← macOS system config + Homebrew
│   └── home-manager
│       └── home/joni.nix               ← shared packages + programs
│           ├── home/zsh.nix            ← unified shell config
│           └── home/theme-kitty.nix    ← Kitty terminal theme
│
└── nixosConfigurations.mothership       ← Linux workstation
    ├── hosts/mothership/...             ← NixOS system config
    └── home-manager
        └── home/joni.nix               ← same shared packages
            ├── home/zsh.nix            ← same shell config
            ├── home/hyprland.nix       ← Hyprland DE + Catppuccin theming
            ├── home/plasma6.nix        ← Plasma6 DE config
            └── home/theme-kitty.nix    ← same Kitty theme
```

Platform differences are handled via `isLinux`/`isDarwin` flags passed through `extraSpecialArgs` in the flake.

## macOS System Defaults

Configured in `hosts/macbook/default.nix`:
- Dock: auto-hide, no recent apps
- Finder: show all extensions, column view
- Keyboard: fast key repeat (2), short initial delay (15)
- Trackpad: tap to click, right-click enabled
- Touch ID: enabled for sudo

## Troubleshooting

### "error: file was not found in the Nix store"
New files need to be tracked by git before nix can see them:
```bash
git add .
darwin-rebuild switch --flake .#jsz-mac-01
```

### Homebrew cask was removed unexpectedly
`cleanup = "zap"` removes anything not declared. Add the cask to `hosts/macbook/default.nix`.

### Shell changes not taking effect
Home-manager writes to `~/.zshrc`. If you have a conflicting `~/.zshrc`, rename it:
```bash
mv ~/.zshrc ~/.zshrc.pre-nix
darwin-rebuild switch --flake .#jsz-mac-01
```

### "could not connect to the Nix daemon"
Restart the daemon:
```bash
sudo launchctl kickstart -k system/org.nixos.nix-daemon
```
