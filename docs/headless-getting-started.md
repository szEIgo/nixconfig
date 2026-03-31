# Headless Getting Started

Install NixOS on headless machines (worker nodes, NUCs, servers).
Two methods available: **nixos-anywhere** (automated, recommended) or **manual install**.

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

# Flash to USB (replace /dev/sdX with your USB device)
sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress
```

Alternatively, use the stock NixOS minimal ISO and manually start sshd:

```bash
# On the target console after booting the stock ISO:
passwd              # set temp root password
systemctl start sshd
ip a                # note the IP
```

### Deploy a Worker Node

From the mothership, one command does everything:

```bash
./scripts/bootstrap/deploy-worker.sh <hostname> <ip>

# Example:
./scripts/bootstrap/deploy-worker.sh node5 192.168.2.147
```

Or via the Makefile:

```bash
make deploy-worker HOST=node5 IP=192.168.2.147
```

**What the script does:**

1. Generates an SSH host key for the node
2. Derives the age key and adds it to `.sops.yaml`
3. Re-encrypts secrets so the node can decrypt them (k3s token)
4. Runs `nixos-anywhere` to partition, install, configure, and reboot

**What the node gets after reboot:**

- GRUB bootloader (legacy BIOS)
- ext4 root filesystem on `/dev/sda`
- SSH key auth (your authorized_keys)
- k3s agent with token (deployed via sops — auto-joins the cluster)
- zsh + powerlevel10k + home-manager
- Full firewall config (SSH, kubelet, flannel, WireGuard)
- Trusted nix user (for remote rebuilds)

### Deploy Multiple Nodes

```bash
# Sequential
for node in "node5 192.168.2.147" "node6 192.168.2.192" "node9 192.168.2.250" "node12 192.168.2.238"; do
    set -- $node
    ./scripts/bootstrap/deploy-worker.sh $1 $2
done

# Parallel (all at once)
./scripts/bootstrap/deploy-worker.sh node5 192.168.2.147 &
./scripts/bootstrap/deploy-worker.sh node6 192.168.2.192 &
./scripts/bootstrap/deploy-worker.sh node9 192.168.2.250 &
./scripts/bootstrap/deploy-worker.sh node12 192.168.2.238 &
wait
```

### Verify

```bash
# SSH in (should work without password)
ssh joni@<ip>

# Check k3s joined the cluster (from mothership)
kubectl get nodes
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

It handles partitioning, formatting (with labels), and installing a minimal NixOS
with flakes and git enabled.

### 3. Reboot and Apply Flake

After reboot, SSH in and apply the full config:

```bash
ssh joni@<ip>
git clone https://github.com/szeigo/nixconfig ~/nixconfig
cd ~/nixconfig
sudo nixos-rebuild switch --flake .#<hostname>
```

### 4. Add SSH Keys and Secrets

From any machine that can reach the new host:

```bash
make add-host-keys HOST=<hostname> IP=<ip>
```

This will:
- Generate an SSH key pair on the host
- Get the host's age key for SOPS decryption
- Add the age key to `.sops.yaml`
- Encrypt the private key in `secrets/secrets.yaml`
- Add the public key to `remote/authorized_keys`
- Create `secrets/<hostname>.nix`

Then add SOPS to the host's entry in `flake.nix`:

```nix
sops-nix.nixosModules.sops
./secrets/<hostname>.nix
```

Push and rebuild:

```bash
git add -A && git commit -m "Add <hostname>"
make switch HOST=<hostname>
```

### 5. Join k3s Cluster (worker nodes only)

If not using the automated deploy-worker.sh method, place the token manually:

```bash
# On the mothership
sudo cat /var/lib/rancher/k3s/server/node-token

# On the worker
sudo mkdir -p /etc/k3s
echo "<token>" | sudo tee /etc/k3s/token
sudo systemctl restart k3s
```

Verify on the mothership:

```bash
kubectl get nodes
```

---

## Comparison

| | nixos-anywhere (Method 1) | Manual Install (Method 2) |
|---|---|---|
| **Steps on target** | Plug USB, power on | Plug USB, start sshd, note IP |
| **Steps on mothership** | One command | Clone, rebuild, add-host-keys |
| **Disk layout** | Declarative (disko) | Interactive (script prompts) |
| **Secrets (k3s token)** | Auto-deployed via sops | Manual token placement |
| **SSH keys** | Pre-generated, deployed automatically | Generated post-install |
| **Time per node** | ~5 minutes | ~15-20 minutes |
| **Scales to 300 nodes** | Yes (parallel) | No |

---

**Next:** [Daily Usage](usage.md) | [Getting Started (Desktop)](getting-started.md)
