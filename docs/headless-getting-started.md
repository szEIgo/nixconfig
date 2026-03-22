# Headless Getting Started

Install NixOS on a headless machine (NUC, server, etc.) from a live ISO.

**Navigation:** [README](../README.md) | [Getting Started](getting-started.md) | [Usage](usage.md)

---

## 1. Boot NixOS ISO

Flash the [NixOS minimal ISO](https://nixos.org/download.html) to a USB stick, plug it in, and boot.

Enable SSH on the live ISO so you can work from your laptop:

```bash
passwd                   # set temp root password
systemctl start sshd
ip a                     # note the DHCP address
```

SSH in from your laptop: `ssh root@<ip>`

## 2. Run the Installer

```bash
nix-shell -p git gnumake
git clone https://github.com/szeigo/nixconfig ~/nixconfig
cd ~/nixconfig
make install
```

The script will prompt you for:
- Which disk to install on
- Hostname
- Username and password

It handles partitioning, formatting (with labels, not UUIDs), and installing.

## 3. Reboot and Apply Flake

After reboot, SSH in and apply the full configuration:

```bash
ssh joni@<dhcp-ip>

nix-shell -p git
git clone https://github.com/szeigo/nixconfig ~/nixconfig
cd ~/nixconfig
make switch HOST=<hostname>
```

## 4. Add SSH Keys

From the **mothership** (or any machine with the repo), run:

```bash
make add-host-keys HOST=<hostname> IP=<ip>
```

This will:
- SSH into the new host and generate an ed25519 key pair
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
git add -A && git commit -m "Add SSH keys for <hostname>"
make switch HOST=<hostname>
```

## 5. Join k3s Cluster (worker nodes only)

```bash
# On the mothership — get the join token
sudo cat /var/lib/rancher/k3s/server/node-token

# On the worker — place the token
sudo mkdir -p /etc/k3s
echo "<token>" | sudo tee /etc/k3s/token
sudo systemctl restart k3s
```

Verify on the mothership:

```bash
kubectl get nodes
```

---

**Next:** [Daily Usage](usage.md) | [Getting Started (Desktop)](getting-started.md)
