---
type: community
cohesion: 0.36
members: 8
---

# ZFS Storage & Pools

**Cohesion:** 0.36 - loosely connected
**Members:** 8 nodes

## Members
- [[Game Storage (ZFS)]] - document - docs/games.md
- [[LUKS Encryption]] - document - docs/getting-started.md
- [[OpenEBS ZFS CSI]] - document - docs/virtualization.md
- [[ZFS Maintenance Guide]] - document - docs/zfs.md
- [[ZFS Storage]] - document - README.md
- [[fastPool (NVMe ZFS Pool)]] - document - docs/getting-started.md
- [[rpool (System ZFS Pool)]] - document - docs/getting-started.md
- [[slowPool (HDD RAIDZ Pool)]] - document - docs/getting-started.md

## Live Query (requires Dataview plugin)

```dataview
TABLE source_file, type FROM #community/ZFS_Storage_&_Pools
SORT file.name ASC
```

## Connections to other communities
- 1 edge to [[_COMMUNITY_Desktop & Workstations]]
- 1 edge to [[_COMMUNITY_K3s Cluster & Networking]]

## Top bridge nodes
- [[ZFS Storage]] - degree 4, connects to 1 community
- [[OpenEBS ZFS CSI]] - degree 3, connects to 1 community