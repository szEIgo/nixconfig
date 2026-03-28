# Headless Getting Started

Install NixOS on a headless machine (NUC, server, etc.) from a live ISO.
Also works for laptops — just connect a monitor for the initial ISO boot, or
prepare the disk on another machine using filesystem labels.

**Navigation:** [README](../README.md) | [Getting Started](getting-started.md) | [Usage](usage.md)

---

## 1. Boot NixOS ISO

Flash the [NixOS minimal ISO](https://nixos.org/download.html) to a USB stick, plug it in, and boot.

Enable SSH on the live ISO so you can work from another machine:

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
Labels make the disk portable between machines — no UUID mismatches.

## 3. Reboot and Get Hardware Config

After reboot, SSH in and generate the real hardware config:

```bash
ssh joni@<dhcp-ip>
nixos-generate-config --show-hardware-config
```

Save this output — you'll need it for `hosts/<hostname>/hardware.nix`.

## 4. Create Host Config (if not already done)

On your main machine (mothership or wherever you edit the repo):

```bash
mkdir -p hosts/<hostname>
```

Create `configuration.nix` and `hardware.nix` using existing hosts as templates:
- **Desktop laptop**: `hosts/t480/` or `hosts/x250/`
- **Headless server/worker**: `hosts/nuc/`
- **Workstation**: `hosts/mothership/`

Merge the `nixos-generate-config` output into `hardware.nix`, keeping custom
additions (network.nix import, `i915` initrd module for Intel, etc).

Add a `nixosConfigurations.<hostname>` entry to `flake.nix` (copy an existing one).

Stage and verify:

```bash
git add hosts/<hostname>/
nix eval .#nixosConfigurations.<hostname>.config.networking.hostName
```

Push to git.

## 5. Apply Flake

SSH into the new host, clone the repo, and apply:

```bash
ssh joni@<dhcp-ip>

nix-shell -p git
git clone https://github.com/szeigo/nixconfig ~/nixconfig
cd ~/nixconfig
make switch HOST=<hostname>
```

## 6. Add SSH Keys

From any machine that can reach the new host:

```bash
make add-host-keys HOST=<hostname> IP=<ip>
```

This will:
- Generate an ed25519 key pair on the host
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

Rebuild other hosts to pick up the new authorized key.

## 7. Join k3s Cluster (worker nodes only)

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
