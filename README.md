# NixConfig

Multi-platform Nix configuration for NixOS (mothership) and macOS (jsz-mac-01).

---

## Fra Distro-Nomade til Nix-Evangelist: 20 års jagt på "The One OS"

<details>
<summary><b>Min rejse til NixOS (klik for at læse)</b></summary>

### 2006: Den spæde start (OpenSUSE & XP-syndromet)

Min rejse startede som 12-årig med en aflagt server og OpenSUSE. Jeg følte mig som en troldmand i 10 minutter, indtil jeg indså, at mine spil krævede Windows. Jeg flygtede tilbage til Windows XP, men nysgerrigheden var vakt.

### 2011-2014: Matrix-drømme og Android-kirurgi

Inden jeg landede fast på Linux igen, røg jeg dybt ned i Android modding-miljøet. Hvis det kunne flashes, blev det flashet. Det lærte mig værdien af root-adgang og risikoen for "bricks" – en god forberedelse til det, der fulgte.

I 2014 vendte jeg hjem til Linux via Ubuntu 14.04. Det var her, mine "hacker-drømme" for alvor tog fart med Backtrack 4/5. Jeg fattede intet om porte, men jeg lærte at cracke WPA-nøgler og lege med WiFi Pineapples. Jeg blev aldrig rig på det, men følelsen af magt over netværket var rigelig betaling.

### Distro-Hopping som ekstremsport

I de følgende år blev jeg en sand IT-nomade. Jeg har været hele vejen rundt for at finde det perfekte fix:

- **Debian & Mint:** For stabiliteten (og kedsomheden).
- **Manjaro & EndeavourOS:** Da jeg ville have Arch-power uden de manuelle tæsk.
- **Slackware & NomadBSD:** Fordi jeg kortvarigt troede, jeg var hardcore nok til det helt rå setup.
- **Tails:** Når paranoiaen ramte.
- **PhotonOS & ProtonOS:** Da container-verdenen og specialiserede miljøer begyndte at trække.

Jeg har skiftet Desktop Environments (DE) oftere, end folk skifter sokker. Fra Unitys storhedstid til GNOME, KDE Plasma, og diverse Tiling Window Managers. Hver gang var det det samme: En uges opsætning, to ugers nydelse, og så et system, der langsomt blev "beskidt" af konfigurations-filer og uoverskuelige dependencies.

### 2017: Arch-oplysningen og GPU-magi

På datamatiker-studiet blev Arch Linux min nye religion. Ingen installer, ingen nåde. Her lærte jeg den hårde skole om EFI-partitioner og GRUB. Det var her, jeg knækkede koden til den ultimative hybrid: **GPU Passthrough**. Med KVM, Libvirt og det geniale Looking Glass-projekt, kunne jeg endelig køre Windows-spil i en VM med 99,9% native performance fra min Linux-host.

### TDC-æraen: Scala og den "hemmelige" lytning

Karrieren startede i TDC som Scala-udvikler under vingerne på min mentor, "Mr. Anderson". Han lærte mig, at mens objektorientering er fint, så er funktionel programmering den sande vej. Som ansvarlig for en FreeSwitch-instans opdagede jeg, hvor hullet SIP-protokollen er. Jeg morede mig med at spoofe opkald internt og lytte med via Wireshark – rent teknisk skadefryd uden økonomisk bagtanke.

### 2026: Destinationen er NixOS

Efter 20 års rodløshed har jeg fundet **"The One OS to Rule Them All": NixOS**.

Efter at have brændt nallerne på alt fra Slackware til Tails, er NixOS det første system, der rent faktisk giver mening for en "praktisk nørd":

- **Farvel til muterbart kaos:** Ingen "rådne" installationer.
- **Deklarativ magi:** Hele min rejse – fra Zen-kernel og IOMMU-grupper til mine personlige genveje – bor i ét Git-repo.
- **Reproducerbarhed:** Hvis min maskine dør, tager det mig under en time at genskabe 20 års tweaks. `sudo nixos-rebuild switch`, og jeg er live.

> *NixOS er ikke bare en distribution; det er kulminationen på to årtiers søgen efter et system, der er lige så klogt som brugeren (på en god dag).*

</details>

---

## Quick Reference

```bash
make help                    # Show all commands
make switch                  # Apply NixOS configuration
make update                  # Update flake inputs and rebuild
make gc                      # Garbage collect (default: 30 days)
```

## Documentation

| Doc | Description |
|-----|-------------|
| [Getting Started](docs/getting-started.md) | Fresh install guide |
| [Daily Usage](docs/usage.md) | Common operations |
| [Structure](docs/structure.md) | Repository layout |
| [Secrets](docs/secrets.md) | SOPS-nix setup |
| [ZFS](docs/zfs.md) | Storage management |
| [Virtualization](docs/virtualization.md) | VMs, MicroVMs, K3s |
| [macOS](docs/darwin.md) | nix-darwin setup |
| [Bootstrap](docs/bootstrap.md) | New machine setup |

## Hosts

| Host | Platform | Type | Description |
|------|----------|------|-------------|
| `mothership` | NixOS x86_64 | Desktop | Main workstation with GPU passthrough |
| `t480` | NixOS x86_64 | Laptop | ThinkPad T480 portable workstation |
| `nuc` | NixOS x86_64 | Server | Headless k3s worker node |
| `android` | nix-on-droid aarch64 | Mobile | Android phone (shared shell/CLI) |
| `jsz-mac-01` | macOS aarch64 | Workstation | MacBook with nix-darwin |

## System Overview

```
mothership (NixOS - Desktop)
├── Desktop: Hyprland / KDE Plasma 6 (plasma-manager)
├── GPU: VFIO passthrough (NVIDIA + AMD)
├── Storage: ZFS (rpool, slowPool, fastPool)
├── K3s: Kubernetes control plane + NFS server (democratic-csi)
├── MicroVMs: k3s workers (10.100.0.11-13, node-type=microvm)
├── VMs: Windows 11, Arch Linux (libvirt)
├── Shell: zsh + powerlevel10k + oh-my-zsh (system-wide)
└── Secrets: sops-nix

t480 (NixOS - Laptop)
├── Desktop: KDE Plasma 6 (plasma-manager, shared config with mothership)
├── Power: TLP (20-80% battery thresholds), thermald, powertop
├── Network: NetworkManager (WiFi)
├── Shell: zsh + powerlevel10k + oh-my-zsh (system-wide)
└── No: ZFS, virtualization, k3s, gaming

nuc (NixOS - Headless Server)
├── Role: k3s worker (joins mothership at 192.168.2.62:6443)
├── Labels: node-type=bare-metal, node-id=nuc, node-role=customer
├── Storage: local ext4 (hostPath), NFS client (democratic-csi)
├── Customer workloads: pinned here, survives mothership downtime
├── Lid/power: all events ignored (headless)
├── Shell: zsh + powerlevel10k + oh-my-zsh (system-wide)
└── No: desktop, plasma, hyprland, virtualization

android (nix-on-droid)
├── Shell: zsh + powerlevel10k + oh-my-zsh (home-manager)
├── CLI: Core tools (eza, bat, ripgrep, fzf, helix, git, etc.)
├── No: desktop, heavy dev tools, systemd services
└── Deploy: nix-on-droid switch --flake ~/nixconfig

jsz-mac-01 (macOS)
├── Nix: CLI tools, dev environment
├── Homebrew: GUI apps (managed by nix-darwin)
└── Shared: Shell config, helix, kitty
```

### Feature Matrix

| Feature | mothership | t480 | nuc | android | macbook |
|---------|:---:|:---:|:---:|:---:|:---:|
| Plasma 6 (plasma-manager) | ✓ | ✓ | - | - | - |
| Hyprland | ✓ | ✓* | - | - | - |
| Home-manager | ✓ | ✓ | ✓ | ✓ | ✓ |
| zsh/p10k/oh-my-zsh | ✓ | ✓ | ✓ | ✓ | ✓ |
| Core CLI tools | ✓ | ✓ | ✓ | ✓ | ✓ |
| Dev tools (rust, scala, k8s) | ✓ | ✓ | ✓ | - | ✓ |
| K3s server | ✓ | - | - | - | - |
| K3s agent | - | - | ✓ | - | - |
| ZFS | ✓ | - | - | - | - |
| Libvirt/VFIO | ✓ | - | - | - | - |
| Podman | ✓ | - | - | - | - |
| MicroVMs | ✓ | - | - | - | - |
| Gaming (Steam) | ✓ | - | - | - | - |
| TLP power mgmt | - | ✓ | - | - | - |
| sops-nix secrets | ✓ | - | - | - | - |
| SSH server | ✓ | ✓ | ✓ | - | - |

\* Hyprland config imported via home-manager but Plasma is the primary DE

## Command Categories

### NixOS Operations
```bash
make switch [HOST=...]       # Build and switch
make build [HOST=...]        # Build only
make test [HOST=...]         # Test without bootloader
make update [HOST=...]       # Update inputs + rebuild
make gc [DAYS=30]            # Garbage collect
```

### Secrets
```bash
make secrets-edit            # Edit secrets.yaml
make secrets-updatekeys      # Re-encrypt for all hosts
make bootstrap               # Decrypt master key (new machine)
make cleanup                 # Remove temporary keys
```

### Storage (ZFS)
```bash
make mount                   # Import and decrypt pools
make zfs-status              # Pool and dataset status
make zfs-scrub               # Start integrity scrub
make zfs-snapshot DATASET=.. # Create snapshot
```

### Virtualization
```bash
make vm-list                 # List all libvirt VMs
make vm-start VM=...         # Start VM
make vm-stop VM=...          # Stop VM
make vm-console VM=...       # Open VM console
make gpu-reset               # Reset AMD GPU
make usb-attach VM=...       # Attach USB to VM
```

### MicroVMs
```bash
make microvm-list            # List MicroVMs
make microvm-start [VM=...]  # Start VMs
make microvm-stop VM=...     # Stop VM
make microvm-ssh VM=...      # SSH via VSOCK
make microvm-init-zfs        # Create ZFS volumes
```

### Kubernetes (K3s)
```bash
make k3s-init                # Setup kubeconfig
make k3s-status              # Cluster status
make k3s-flux-bootstrap      # Install Flux CD
make k3s-flux-status         # Flux status
```

## Directory Structure

```
nixconfig/
├── flake.nix                # Entry point
├── Makefile                 # All operations
├── hosts/                   # Machine configs
│   ├── mothership/          # NixOS desktop
│   ├── t480/                # NixOS laptop
│   ├── nuc/                 # NixOS headless k3s worker
│   ├── android/             # nix-on-droid (Android)
│   └── macbook/             # macOS
├── modules/                 # Reusable NixOS modules
│   ├── core/                # Required for all hosts
│   ├── common/              # Desktop extensions
│   ├── desktop/             # Hyprland, Plasma
│   └── virtualization/      # VMs, k3s, podman
├── home/                    # Home-manager (all platforms)
│   ├── joni.nix             # Main user config
│   ├── shell/               # Zsh config
│   └── profiles/            # Composable profiles
├── secrets/                 # SOPS-encrypted secrets
├── scripts/                 # Management scripts
└── docs/                    # Documentation
```

## License

Personal configuration - use at your own risk.
