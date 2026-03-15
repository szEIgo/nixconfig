# Bootstrap Guide

How to set up this NixOS configuration on a new machine.

## Prerequisites

- NixOS installed (or nix-darwin for macOS)
- Flakes enabled
- Access to `secrets/id_mothership.age` passphrase

## Quick Start (NixOS)

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USER/nixconfig
cd nixconfig

# 2. Run the bootstrap script (prompts for passphrase)
make bootstrap

# 3. Add this machine's age key to .sops.yaml
#    The script shows the key - add it as a new entry

# 4. Re-encrypt secrets for this machine
make secrets-updatekeys

# 5. Create host configuration (see "Adding a New Host" below)

# 6. Build and switch
make switch HOST=hostname

# 7. Clean up (secrets now decrypt via SSH host key)
make cleanup
```

## Available Commands

Run `make help` to see all available commands.

## Adding a New Host

### 1. Create Host Directory

```bash
mkdir -p hosts/myhostname
```

### 2. Create configuration.nix

```nix
# hosts/myhostname/configuration.nix
{ config, lib, pkgs, ... }: {
  imports = [
    # Desktop groups, zsh, etc. (skip for servers)
    ../../modules/common/users.nix
    ../../modules/common/zsh.nix

    # Add modules as needed:
    # ../../modules/virtualization/podman.nix
    # ../../modules/virtualization/k3s.nix
    # ../../remote/ssh.nix
  ];

  networking.hostName = "myhostname";
  networking.hostId = "xxxxxxxx";  # head -c 8 /etc/machine-id

  system.stateVersion = "25.11";
}
```

### 3. Generate hardware.nix

```bash
nixos-generate-config --show-hardware-config > hosts/myhostname/hardware.nix
```

### 4. Add to flake.nix

```nix
nixosConfigurations = {
  # ... existing hosts ...

  myhostname = mkNixosHost {
    system = "x86_64-linux";  # or "aarch64-linux" for ARM
    hostName = "myhostname";
    hostType = "desktop";     # or "server" or "workstation"
  };
};
```

### Host Types

| Type | Profiles Included | Use Case |
|------|-------------------|----------|
| `"server"` | base.nix | Headless servers, Raspberry Pis |
| `"workstation"` | base.nix, dev.nix | Development machines without desktop |
| `"desktop"` | base.nix, dev.nix, desktop.nix | Full desktop with GUI |

## macOS Setup

### Home-Manager Only (Current)

```bash
# Apply home-manager configuration
home-manager switch --flake .#"joni@hostname"
```

### With nix-darwin (Future)

Uncomment nix-darwin in `flake.nix` and run:
```bash
nix run nix-darwin -- switch --flake .#macbook
```

## Secrets Setup

### 1. Get Machine's Age Key

```bash
nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'
```

### 2. Add to .sops.yaml

```yaml
keys:
  - &joni age1798uc9...
  - &mothership age13m0dh...
  - &newmachine age1xxxx...  # Add here

creation_rules:
  - path_regex: secrets/secrets\.yaml$
    key_groups:
      - age:
          - *joni
          - *mothership
          - *newmachine  # Reference here
```

### 3. Re-encrypt

```bash
sops updatekeys secrets/secrets.yaml
```

## Editing Secrets

```bash
# Edit secrets (handles master key automatically)
make secrets-edit

# After editing, clean up the master key
make cleanup
```

## Troubleshooting

### "sops metadata not found"
The secrets.yaml file isn't encrypted. Run `sops -e -i secrets/secrets.yaml`.

### "could not decrypt data key"
Your key isn't in `.sops.yaml`. Add it and run `sops updatekeys secrets/secrets.yaml`.

### Secrets not appearing at boot
Check `systemctl status sops-nix` and ensure the SSH host key exists at `/etc/ssh/ssh_host_ed25519_key`.
