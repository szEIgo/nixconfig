---
type: community
cohesion: 0.22
members: 9
---

# Bootstrap & Deployment

**Cohesion:** 0.22 - loosely connected
**Members:** 9 nodes

## Members
- [[Bootstrap Guide]] - document - docs/bootstrap.md
- [[Makefile (Operations)]] - document - README.md
- [[NixConfig Repository]] - document - README.md
- [[Worker ISO]] - document - docs/headless-getting-started.md
- [[disko (Declarative Disk Layout)]] - document - docs/headless-getting-started.md
- [[flake.nix (Entry Point)]] - document - README.md
- [[mkWorker (Fleet Node Builder)]] - document - docs/structure.md
- [[nixos-anywhere]] - document - docs/headless-getting-started.md
- [[sops-nix Secrets]] - document - README.md

## Live Query (requires Dataview plugin)

```dataview
TABLE source_file, type FROM #community/Bootstrap_&_Deployment
SORT file.name ASC
```

## Connections to other communities
- 2 edges to [[_COMMUNITY_K3s Cluster & Networking]]
- 1 edge to [[_COMMUNITY_Desktop & Workstations]]

## Top bridge nodes
- [[nixos-anywhere]] - degree 4, connects to 1 community
- [[sops-nix Secrets]] - degree 3, connects to 1 community
- [[mkWorker (Fleet Node Builder)]] - degree 2, connects to 1 community