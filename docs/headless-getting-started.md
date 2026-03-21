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
sudo nixos-rebuild switch --flake .#nuc
```

Your SSH session will drop when the static IP (`192.168.2.211`) takes over. Reconnect:

```bash
ssh joni@192.168.2.211
```

## 4. Join k3s Cluster

```bash
# On the mothership — get the join token
sudo cat /var/lib/rancher/k3s/server/node-token

# On the NUC — place the token
sudo mkdir -p /etc/k3s
echo "<token>" | sudo tee /etc/k3s/token
sudo systemctl restart k3s-agent

# On the mothership — verify
kubectl get nodes
```

---

**Next:** [Daily Usage](usage.md) | [Getting Started (Desktop)](getting-started.md)
