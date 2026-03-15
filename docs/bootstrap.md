# Bootstrap Guide

How to set up this NixOS configuration on a new machine.

## Prerequisites

- NixOS installed with flakes enabled
- Access to `secrets/id_mothership.age` passphrase

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USER/nixconfig
cd nixconfig

# 2. Run the bootstrap script (prompts for passphrase)
./home/scripts/decrypt-keys.sh

# 3. Add this machine's age key to .sops.yaml
#    The script shows the key - add it as a new entry

# 4. Re-encrypt secrets for this machine
sops updatekeys secrets/secrets.yaml

# 5. Commit and build
git add .sops.yaml secrets/secrets.yaml
sudo nixos-rebuild switch --flake .#mothership

# 6. Clean up (secrets now decrypt via SSH host key)
shred -u ~/.config/sops/age/keys.txt
```

## Step-by-Step

### 1. Clone Repository

```bash
git clone https://github.com/YOUR_USER/nixconfig
cd nixconfig
```

### 2. Decrypt Master Key

Run the bootstrap script:
```bash
./home/scripts/decrypt-keys.sh
```

This will:
- Prompt for the `id_mothership.age` passphrase
- Place the decrypted key where sops expects it
- Display this machine's age public key

### 3. Add Machine to `.sops.yaml`

Edit `.sops.yaml` and add the new machine's key:

```yaml
keys:
  - &joni age1798uc9a5r3f8lsg0utsl5nsflnmrr6d0p6tqhpweldq2j9dftgmqgvjdln
  - &mothership age13m0dh0996244ktl8qq8lst7q9ektpn544rz9fh7n86qnfxu8w3sq830mwa
  - &newmachine age1xxxx...  # Add new key here

creation_rules:
  - path_regex: secrets/secrets\.yaml$
    key_groups:
      - age:
          - *joni
          - *mothership
          - *newmachine  # Add reference here
```

### 4. Re-encrypt Secrets

```bash
sops updatekeys secrets/secrets.yaml
```

### 5. Build Configuration

```bash
# Add new machine config if needed
# Then build:
sudo nixos-rebuild switch --flake .#hostname
```

### 6. Cleanup

After successful boot, remove the temporary master key:
```bash
shred -u ~/.config/sops/age/keys.txt
```

The machine now decrypts secrets automatically using its SSH host key.

## Editing Secrets

To modify secrets after initial setup:

```bash
# Temporarily decrypt master key
age --decrypt -o ~/.config/sops/age/keys.txt secrets/id_mothership.age

# Edit secrets (decrypts in editor, re-encrypts on save)
sops secrets/secrets.yaml

# Clean up
shred -u ~/.config/sops/age/keys.txt
```

## Troubleshooting

### "sops metadata not found"
The secrets.yaml file isn't encrypted. Run `sops -e -i secrets/secrets.yaml`.

### "could not decrypt data key"
Your key isn't in `.sops.yaml`. Add it and run `sops updatekeys secrets/secrets.yaml`.

### Secrets not appearing at boot
Check `systemctl status sops-nix` and ensure the SSH host key exists at `/etc/ssh/ssh_host_ed25519_key`.
