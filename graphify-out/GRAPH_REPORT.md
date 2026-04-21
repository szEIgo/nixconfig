# Graph Report - .  (2026-04-11)

## Corpus Check
- Corpus is ~11,321 words - fits in a single context window. You may not need a graph.

## Summary
- 55 nodes · 63 edges · 8 communities detected
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 2 edges (avg confidence: 0.5)
- Token cost: 0 input · 0 output

## God Nodes (most connected - your core abstractions)
1. `K3s HA Cluster` - 12 edges
2. `Mothership (NixOS Desktop)` - 11 edges
3. `Home-Manager Configuration` - 5 edges
4. `Libvirt KVM/QEMU` - 5 edges
5. `ZFS Storage` - 4 edges
6. `VFIO GPU Passthrough` - 4 edges
7. `slowPool (HDD RAIDZ Pool)` - 4 edges
8. `nix-darwin` - 4 edges
9. `nixos-anywhere` - 4 edges
10. `flake.nix (Entry Point)` - 3 edges

## Surprising Connections (you probably didn't know these)
- `Mothership (NixOS Desktop)` --references--> `NFS Server Module`  [EXTRACTED]
  README.md → docs/structure.md
- `K3s HA Cluster` --references--> `mkWorker (Fleet Node Builder)`  [EXTRACTED]
  README.md → docs/structure.md
- `WireGuard VPN` --references--> `Mothership (NixOS Desktop)`  [EXTRACTED]
  docs/usage.md → README.md
- `MicroVMs (Disabled)` --references--> `Mothership (NixOS Desktop)`  [EXTRACTED]
  docs/virtualization.md → README.md
- `K3s HA Cluster` --references--> `Flannel VXLAN Networking`  [EXTRACTED]
  README.md → docs/virtualization.md

## Communities

### Community 0 - "K3s Cluster & Networking"
Cohesion: 0.18
Nodes (11): carrier-tc1 (Control Plane), carrier-tc2 (Control Plane), deploy-rs, interceptor-nuc1 (Worker), interceptor-tc1 (Worker), interceptor-tc2 (Worker), K3s HA Cluster, NFS Server Module (+3 more)

### Community 1 - "Bootstrap & Deployment"
Cohesion: 0.22
Nodes (9): Bootstrap Guide, disko (Declarative Disk Layout), nixos-anywhere, Worker ISO, flake.nix (Entry Point), Makefile (Operations), NixConfig Repository, sops-nix Secrets (+1 more)

### Community 2 - "Desktop & Workstations"
Cohesion: 0.28
Nodes (9): Hyprland WM, Mothership (NixOS Desktop), KDE Plasma 6, Podman Containers, Steam Gaming, t480 (NixOS Laptop), WireGuard VPN, desktop.nix Profile (+1 more)

### Community 3 - "ZFS Storage & Pools"
Cohesion: 0.36
Nodes (8): Game Storage (ZFS), fastPool (NVMe ZFS Pool), LUKS Encryption, rpool (System ZFS Pool), slowPool (HDD RAIDZ Pool), ZFS Storage, OpenEBS ZFS CSI, ZFS Maintenance Guide

### Community 4 - "Cross-Platform & Profiles"
Cohesion: 0.25
Nodes (8): Determinate Nix Installer, Homebrew (Declarative), nix-darwin, Android (nix-on-droid), Home-Manager Configuration, jsz-mac-01 (macOS), base.nix Profile, dev.nix Profile

### Community 5 - "VM & GPU Passthrough"
Cohesion: 0.47
Nodes (6): VFIO GPU Passthrough, archlinux VM, Libvirt KVM/QEMU, NixVirt, win11-amd VM, win11-nvidia VM

### Community 6 - "Plymouth Boot Theme"
Cohesion: 0.67
Nodes (3): XX-Eyes Grinning Smiley Face Icon, Plymouth Boot Theme Logo, Plymouth Boot Theme Module

### Community 7 - "Legacy Laptops"
Cohesion: 1.0
Nodes (1): x250 (NixOS Laptop)

## Knowledge Gaps
- **24 isolated node(s):** `carrier-tc1 (Control Plane)`, `carrier-tc2 (Control Plane)`, `interceptor-nuc1 (Worker)`, `interceptor-tc1 (Worker)`, `interceptor-tc2 (Worker)` (+19 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Legacy Laptops`** (1 nodes): `x250 (NixOS Laptop)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Mothership (NixOS Desktop)` connect `Desktop & Workstations` to `K3s Cluster & Networking`, `Bootstrap & Deployment`, `ZFS Storage & Pools`, `VM & GPU Passthrough`?**
  _High betweenness centrality (0.608) - this node is a cross-community bridge._
- **Why does `K3s HA Cluster` connect `K3s Cluster & Networking` to `Bootstrap & Deployment`, `Desktop & Workstations`, `ZFS Storage & Pools`?**
  _High betweenness centrality (0.357) - this node is a cross-community bridge._
- **Why does `desktop.nix Profile` connect `Desktop & Workstations` to `Cross-Platform & Profiles`?**
  _High betweenness centrality (0.235) - this node is a cross-community bridge._
- **What connects `carrier-tc1 (Control Plane)`, `carrier-tc2 (Control Plane)`, `interceptor-nuc1 (Worker)` to the rest of the system?**
  _24 weakly-connected nodes found - possible documentation gaps or missing edges._