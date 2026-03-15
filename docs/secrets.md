# Secrets Management

This configuration uses [sops-nix](https://github.com/Mic92/sops-nix) for secrets management.

## Architecture

```
secrets/
├── id_mothership.age      # Password-protected master key (for bootstrapping)
├── secrets.yaml           # SOPS-encrypted secrets (safe for Git)
├── secrets.nix            # NixOS module defining where secrets go
└── *.pub                  # Public keys (not sensitive)
```

## How It Works

### At Boot (Automatic)
- sops-nix uses the machine's SSH host key (`/etc/ssh/ssh_host_ed25519_key`) to decrypt `secrets.yaml`
- Secrets are placed at their configured paths (e.g., `/home/joni/.ssh/`, `/etc/secrets/`)
- No password required

### For Bootstrapping/Editing (Manual)
- `secrets/id_mothership.age` is the master key, protected by a passphrase
- This key can decrypt `secrets.yaml` on any machine
- Only needed when setting up a new machine or editing secrets

## Files Requiring Password

| File | When | Purpose |
|------|------|---------|
| `secrets/id_mothership.age` | Bootstrap only | Master decryption key |

## Secrets Deployed at Runtime

| Secret | Deployed To | Owner |
|--------|-------------|-------|
| `ssh_id_ecdsa` | `/home/joni/.ssh/id_ecdsa` | joni |
| `ssh_mothership` | `/home/joni/.ssh/mothership` | joni |
| `wireguard_private_key` | `/etc/secrets/mothership_wg_private.key` | root:systemd-network |

## Key Management

### Machine Keys (in `.sops.yaml`)
Each machine has an age key derived from its SSH host key:
```bash
nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'
```

### Personal Master Key
- Stored as `secrets/id_mothership.age` (passphrase-protected)
- Public key: `age1798uc9a5r3f8lsg0utsl5nsflnmrr6d0p6tqhpweldq2j9dftgmqgvjdln`
- Used for bootstrapping new machines and editing secrets
