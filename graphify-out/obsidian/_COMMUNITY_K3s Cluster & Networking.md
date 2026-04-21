---
type: community
cohesion: 0.18
members: 11
---

# K3s Cluster & Networking

**Cohesion:** 0.18 - loosely connected
**Members:** 11 nodes

## Members
- [[Flannel VXLAN Networking]] - document - docs/virtualization.md
- [[Flux CD (GitOps)]] - document - docs/virtualization.md
- [[K3s HA Cluster]] - document - README.md
- [[NFS Server Module]] - document - docs/structure.md
- [[carrier-tc1 (Control Plane)]] - document - README.md
- [[carrier-tc2 (Control Plane)]] - document - README.md
- [[democratic-csi (NFS)]] - document - docs/virtualization.md
- [[deploy-rs]] - document - README.md
- [[interceptor-nuc1 (Worker)]] - document - README.md
- [[interceptor-tc1 (Worker)]] - document - README.md
- [[interceptor-tc2 (Worker)]] - document - README.md

## Live Query (requires Dataview plugin)

```dataview
TABLE source_file, type FROM #community/K3s_Cluster_&_Networking
SORT file.name ASC
```

## Connections to other communities
- 2 edges to [[_COMMUNITY_Desktop & Workstations]]
- 2 edges to [[_COMMUNITY_Bootstrap & Deployment]]
- 1 edge to [[_COMMUNITY_ZFS Storage & Pools]]

## Top bridge nodes
- [[K3s HA Cluster]] - degree 12, connects to 3 communities
- [[deploy-rs]] - degree 2, connects to 1 community
- [[NFS Server Module]] - degree 2, connects to 1 community