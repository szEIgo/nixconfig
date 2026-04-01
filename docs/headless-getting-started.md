# Headless Getting Started

Install NixOS on headless fleet nodes (carriers, interceptors, or any new server).

**Navigation:** [README](../README.md) | [Getting Started](getting-started.md) | [Usage](usage.md)

---

## Method 1: nixos-anywhere + disko (Recommended)

Fully automated: partitions the disk, installs NixOS with the full flake config,
deploys secrets (k3s token), and reboots. One command from the mothership.

### Prerequisites

- Target machine booted from the **worker ISO** (or any NixOS live USB with sshd running)
- Network connectivity between mothership and target

### Build the Worker ISO (one-time)

The custom worker ISO boots with sshd enabled and your SSH keys on root,
so nixos-anywhere can connect without any manual setup on the target.

```bash
# Build the ISO
nix build .#images.worker-iso

# Flash to USB
make flash-worker-iso
```

### Deploy a Fleet Node

From the mothership, one command does everything:

```bash
make deploy-new HOST=carrier-tc1 IP=192.168.2.192
```

**What the script does:**

1. Generates an SSH host key for the node
2. Derives the age key and adds it to `.sops.yaml`
3. Re-encrypts secrets so the node can decrypt them (k3s token)
4. Runs `nixos-anywhere` to partition, install, configure, and reboot

**What the node gets after reboot:**

- Bootloader (GRUB or systemd-boot depending on `bootMode`)
- ext4 root filesystem via disko
- SSH key auth (your authorized_keys)
- k3s with correct role (server/agent) and labels
- sops-nix secrets (k3s token auto-deployed)
- systemd ssh-agent + zsh + powerlevel10k + home-manager
- Firewall (SSH, kubelet, flannel, etcd ports for carriers)

### Deploy Multiple Nodes

```bash
# Sequential
make deploy-new HOST=carrier-tc1 IP=192.168.2.192
make deploy-new HOST=interceptor-tc1 IP=192.168.2.238

# Parallel
./scripts/bootstrap/deploy-worker.sh carrier-tc1 192.168.2.192 &
./scripts/bootstrap/deploy-worker.sh interceptor-tc2 192.168.2.147 &
wait
```

### Verify

```bash
# SSH in (should work without password)
ssh carrier-tc1

# Check k3s joined the cluster (from mothership)
kubectl get nodes
```

### Subsequent Updates

After the initial install, use deploy-rs for all future config changes:

```bash
# Single node (with automatic rollback on failure)
make deploy HOST=carrier-tc1

# All fleet nodes
make deploy-all
```

---

## Method 2: Manual Install (headless-install.sh)

Manual method using a bootstrap script. Useful when you need more control
over partitioning, or for non-standard disk layouts.

### 1. Boot NixOS ISO

Flash the [NixOS minimal ISO](https://nixos.org/download.html) to a USB stick, plug it in, and boot.

Enable SSH on the live ISO so you can work from another machine:

```bash
passwd                   # set temp root password
systemctl start sshd
ip a                     # note the DHCP address
```

SSH in from your laptop: `ssh root@<ip>`

### 2. Run the Installer

```bash
nix-shell -p git gnumake
git clone https://github.com/szeigo/nixconfig ~/nixconfig
cd ~/nixconfig
make install
```

The script will prompt you for:
- Which disk to install on
- Boot mode: **UEFI** (GPT + systemd-boot) or **Legacy** (MBR + GRUB)
- Hostname and password

### 3. Reboot and Apply Flake

After reboot, SSH in and apply the full config:

```bash
ssh joni@<ip>
git clone https://github.com/szeigo/nixconfig ~/nixconfig
cd ~/nixconfig
sudo nixos-rebuild switch --flake .#<hostname>
```

### 4. Add SSH Keys and Secrets

From the mothership:

```bash
make add-host-keys HOST=<hostname> IP=<ip>
```

---

## Comparison

| | nixos-anywhere (Method 1) | Manual Install (Method 2) |
|---|---|---|
| **Steps on target** | Plug USB, power on | Plug USB, start sshd, note IP |
| **Steps on mothership** | One command | Clone, rebuild, add-host-keys |
| **Disk layout** | Declarative (disko) | Interactive (script prompts) |
| **Secrets (k3s token)** | Auto-deployed via sops | Manual token placement |
| **Updates** | `make deploy HOST=...` (deploy-rs) | SSH in, git pull, rebuild |
| **Time per node** | ~5 minutes | ~15-20 minutes |

---

**Next:** [Daily Usage](usage.md) | [Getting Started (Desktop)](getting-started.md)
