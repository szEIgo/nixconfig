# Architecture Recommendations

Generated 2026-04-11 from a knowledge graph analysis of the full nixconfig repository.

## The Core Problem

Mothership currently serves 5 distinct roles: desktop workstation, K3s control plane, NFS storage server, VPN endpoint, and VM host. This makes it a single point of failure — a GPU driver crash, ZFS scrub, or reboot to switch GPU specialisation takes down the entire cluster's storage, API access, and ingress.

## Principle: Separate the Planes

Split infrastructure into three independent failure domains:

```
┌─────────────────┐   ┌─────────────────────┐   ┌──────────────────┐
│  COMPUTE PLANE   │   │    STORAGE PLANE      │   │  DESKTOP PLANE    │
│  (k3s cluster)   │   │    (dedicated NAS)     │   │  (workstation)    │
│                  │   │                       │   │                  │
│  carrier-tc1 CP  │   │  NAS node             │   │  mothership      │
│  carrier-tc2 CP  │   │  - ZFS pools          │   │  - gaming/VMs    │
│  interceptor-*   │   │  - NFS server         │   │  - dev work      │
│  (workers)       │   │  - democratic-csi     │   │  - GPU passthru  │
│                  │   │  - OpenEBS target     │   │                  │
└────────┬─────────┘   └──────────┬────────────┘   └──────────────────┘
         │                        │
         └────── 192.168.2.0/24 ──┘
```

## 1. Remove Mothership from the K3s Control Plane

**Current:** Mothership runs `--cluster-init` with keepalived priority 200, making it the primary control plane node and VIP holder. A reboot to switch GPU specialisation takes down the API server leader.

**Proposed:**
- Mothership becomes a pure desktop/VM workstation — no k3s at all, or at most a k3s agent with `PreferNoSchedule` taint for occasional overflow
- carrier-tc1 (8 cores, 16 GB) becomes the `--cluster-init` node with keepalived priority 200
- carrier-tc2 remains a secondary server
- Add a third dedicated control plane node if budget allows (odd number for etcd quorum without mothership)

**Why:** carrier-tc1 already has 8 cores and 16 GB — more than enough for a homelab control plane. Right now it's wasted as a secondary that never leads. Promoting it means the cluster survives mothership reboots, GPU driver crashes, and gaming sessions without blinking.

## 2. Dedicated Storage Node

**Current:** Mothership owns all ZFS pools (rpool, fastPool, slowPool) and serves NFS + OpenEBS to the cluster while also running desktop workloads, VMs, and games on the same disks.

**Proposed:** Move the NAS role to a dedicated storage node (new or repurposed hardware):

| Component | Spec | Why |
|-----------|------|-----|
| CPU | Any modern 4-core (even Celeron/Pentium) | ZFS is not CPU-hungry for NFS serving |
| RAM | 32 GB+ (ECC if possible) | ZFS ARC cache is everything — 1 GB ARC per 1 TB storage is the minimum. ECC prevents silent corruption |
| Boot | Small NVMe or SSD | OS + rpool |
| Fast tier | 1-2 NVMe drives | Replaces fastPool — k3s PVCs, databases |
| Bulk tier | 3+ HDDs in RAIDZ2 | Replaces slowPool — upgrade from RAIDZ1 to RAIDZ2 for double-parity redundancy |
| SLOG (optional) | Small Optane or NVMe partition | ZFS intent log — massively improves NFS sync write latency for k3s workloads |
| Network | 2.5GbE minimum | NFS throughput to cluster |

**Why RAIDZ2 over RAIDZ1:** With RAIDZ1, a single drive failure during a resilver (which stresses all remaining drives) can lose the pool. RAIDZ2 survives two simultaneous failures. For a homelab where you might not notice a failed drive for days, this matters.

**Storage classes become:**

| Class | Backend | Access |
|-------|---------|--------|
| `zfs-local-fast` | NVMe on NAS, OpenEBS zvol | Local to NAS node (schedule pods there for lowest latency) |
| `zfs-local-slow` | HDD RAIDZ2 on NAS, OpenEBS zvol | Local to NAS node |
| `nfs-fast` | NVMe via democratic-csi | Any node in cluster |
| `nfs-slow` | HDD via democratic-csi | Any node in cluster |

Mothership keeps only its rpool for OS + home + VM zvols. No cluster storage duties.

## 3. Upgrade Worker Nodes (or Consolidate)

**Current:**
- interceptor-tc1: 4 cores / 6 GB — small
- interceptor-tc2: 4 cores / 4 GB — very small (can barely run a JVM workload)
- interceptor-nuc1: 4 cores / 8 GB — reasonable

**Option A — Consolidate:** Replace the two ThinkCentres (tc1 + tc2 = 10 GB combined) with a single node with 16-32 GB. Two decent workers (nuc1 + new node) beat three starved ones. Fewer nodes = less etcd overhead, less Flannel traffic, simpler management.

**Option B — Upgrade RAM:** If the ThinkCentres have free DIMM slots, just add RAM. Getting interceptor-tc2 from 4 GB to 8-16 GB is probably the cheapest improvement available. Even 8 GB makes it a usable k3s worker.

## 4. Network Improvements

### Separate storage traffic from cluster traffic

**Current:** Everything (k3s API, Flannel VXLAN, NFS, desktop traffic, WireGuard) shares the same 192.168.2.0/24 LAN.

**Proposed:** Add a dedicated storage VLAN or a second NIC on the NAS + worker nodes:

```
192.168.2.0/24   — management + k3s API + Flannel + desktop
192.168.3.0/24   — storage network (NFS, iSCSI)
```

This prevents a large NFS transfer from starving Flannel pod-to-pod traffic or vice versa. If the switch supports VLANs, this is a config-only change (no new hardware). If not, even a cheap unmanaged switch as a dedicated storage backbone works.

### WireGuard endpoint

**Current:** WireGuard server is on mothership (80.209.114.19:51821). Mothership reboot = VPN down.

**Proposed:** Move WireGuard to carrier-tc1 (or the keepalived VIP). Since carrier-tc1 is now always-on infrastructure, it's a better VPN endpoint. Alternatively, run WireGuard on all control-plane nodes and point the DNS at the VIP — keepalived handles failover.

## 5. Storage Redundancy: ZFS Replication

Even with a dedicated NAS, there is no offsite or cross-node backup.

**Proposed:** Use syncoid (part of sanoid/syncoid) to replicate critical ZFS datasets:

```
NAS:fastPool/k3s  →  syncoid  →  mothership:rpool/backup/k3s   (hourly)
NAS:slowPool/k3s  →  syncoid  →  mothership:rpool/backup/k3s   (daily)
```

This gives a warm backup of cluster persistent volumes on mothership's NVMe. If the NAS dies, storage can failover to mothership temporarily (it already has the NFS module). Add sanoid for automated ZFS snapshot policies (hourly/daily/monthly retention).

## 6. Keepalived & Ingress

**Current:** Keepalived VIP (192.168.2.200) on mothership (priority 200) -> carrier-tc1 (150) -> carrier-tc2 (140). Traefik + Blocky on VIP.

**Proposed:**
- carrier-tc1 priority 200, carrier-tc2 priority 150 — mothership drops out entirely
- Consider MetalLB in L2 mode instead of keepalived — it's k8s-native, assigns VIPs to services directly, handles failover through k8s leader election instead of VRRP. One less thing to configure in NixOS.

## 7. Mothership: Pure Workstation

With the above changes, mothership becomes clean:

| Keeps | Drops |
|-------|-------|
| rpool (OS + home) | k3s control plane |
| Dual GPU + VFIO VMs | NFS server |
| Hyprland / Plasma 6 | keepalived |
| Podman (local dev) | fastPool / slowPool (move to NAS) |
| Steam + game storage (local SSD/NVMe) | OpenEBS duties |
| Binary cache (harmonia) | Flannel/etcd overhead |

Game storage stays local on mothership (a dedicated NVMe or partition) since games don't need cluster access or redundancy. This eliminates the gaming-vs-cluster IOPS contention entirely.

## Before vs After

| Concern | Current | Proposed |
|---------|---------|----------|
| **SPOF** | Mothership does everything | Three independent failure domains |
| **Storage contention** | Games + k3s share fastPool/slowPool | Separate: games on mothership, k3s on NAS |
| **Control plane uptime** | Rebooting mothership loses API leader | carrier-tc1 leads, mothership not in cluster |
| **Data redundancy** | RAIDZ1, no replication | RAIDZ2 + syncoid cross-node replication |
| **Network contention** | Single flat LAN | Storage VLAN separates NFS from pod traffic |
| **VPN availability** | Tied to mothership uptime | On always-on control plane / VIP |
| **Worker capacity** | 3 workers, smallest has 4 GB | Consolidate to fewer, beefier workers |
| **GPU flexibility** | Reboot disrupts cluster | Reboot at will — cluster doesn't care |

## Cheapest Path to Get There

If budget is tight, priority order:

1. **Remove mothership from k3s control plane** — free, config-only, biggest stability win
2. **Move keepalived priority to carrier-tc1** — free, config-only
3. **Move WireGuard to carrier-tc1** — free, config-only
4. **Add RAM to interceptor-tc2** (4 -> 8+ GB) — ~$15 for used DDR3/DDR4
5. **Repurpose any spare box as NAS** — move the HDDs and second NVMe from mothership into it
6. **Add syncoid replication** — free, config-only
7. **Storage VLAN** — free if switch supports it

Steps 1-3 and 6-7 are pure NixOS config changes. Step 5 requires physically moving drives but no new purchases if there is a spare chassis.
