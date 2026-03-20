# Secrets Management

This configuration uses [sops-nix](https://github.com/Mic92/sops-nix) for secrets management across multiple machines.

**Navigation:** [README](../README.md) | [Bootstrap](bootstrap.md) | [Usage](usage.md) | [Structure](structure.md)

---

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
- Works on any machine listed in `.sops.yaml`

### For Bootstrapping/Editing (Manual)
- `secrets/id_mothership.age` is the master key, protected by a passphrase
- This key can decrypt `secrets.yaml` on any machine
- Only needed when setting up a new machine or editing secrets

## Multi-Host Setup

Each host needs its age public key in `.sops.yaml`:

```yaml
keys:
  - &joni age1798uc9...           # Personal master key
  - &mothership age13m0dh...       # Desktop
  - &raspi-k3s-1 age1xxxx...       # Raspberry Pi 1
  - &raspi-k3s-2 age1yyyy...       # Raspberry Pi 2

creation_rules:
  - path_regex: secrets/secrets\.yaml$
    key_groups:
      - age:
          - *joni
          - *mothership
          - *raspi-k3s-1
          - *raspi-k3s-2
```

After adding a new host, re-encrypt:
```bash
sops updatekeys secrets/secrets.yaml
```

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

## Host-Specific Secrets

For secrets that should only be on certain hosts, create separate files:

```yaml
# .sops.yaml
creation_rules:
  - path_regex: secrets/secrets\.yaml$
    key_groups:
      - age: [*joni, *mothership, *raspi-k3s-1, *raspi-k3s-2]

  - path_regex: secrets/desktop\.yaml$
    key_groups:
      - age: [*joni, *mothership]  # Desktop only

  - path_regex: secrets/k3s\.yaml$
    key_groups:
      - age: [*joni, *raspi-k3s-1, *raspi-k3s-2]  # K3s nodes only
```
