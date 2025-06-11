
# ZFS Maintenance & Management Guide
### Pool & Dataset Naming Overview
```
nvmePool/          # NVMe RAID1 pool with system datasets & cache
  root/            # Root dataset (for nix, var, home etc)
  vmdata/          # VM disk images and snapshots
  cache/           # L2ARC and SLOG devices attached here

hddPool/           # HDD RAIDZ pool for bulk storage (games, backups)
  games/           # Games dataset (base installs)
  vmshared/        # Clones for VM-specific game copies
  backups/         # Backup datasets
```
## Pool Creation & Basic Setup

### Create NVMe RAID1 pool (example: adata + kingston)
```
zpool create -f nvmePool mirror /dev/nvme0n1 /dev/nvme1n1 \
  ashift=12
```

### Create HDD RAIDZ pool (example: 2 or more HDDs)
``` zpool create -f hddPool raidz1 /dev/sdX /dev/sdY /dev/sdZ \
  ashift=12 
  ```

## Add Caching & SLOG Devices

### Add L2ARC (read cache) to nvmePool
```
zpool add nvmePool cache /dev/nvme2n1
```

### Add SLOG (ZIL) for sync writes, e.g., dedicated NVMe
```
zpool add nvmePool log /dev/nvme3n1
```

## Dataset Creation
```
zfs create nvmePool/root
zfs create nvmePool/root/nix
zfs create nvmePool/root/home
zfs create nvmePool/root/var
zfs create nvmePool/vmdata
zfs create hddPool/games
zfs create hddPool/vmshared
zfs create hddPool/backups
```

## Mounting
### Mount all pools (auto-mount if enabled)
```
zpool import -a
```
### Manually mount specific dataset
```
zfs mount nvmePool/root
```
## Snapshots & Clones (For VM Shared Games)

### Snapshot base game dataset
```
zfs snapshot hddPool/games/gameX@base
```

### Create VM clone from snapshot (independent writable copy)

```
zfs clone hddPool/games/gameX@base hddPool/vmshared/gameX_vm1
zfs clone hddPool/games/gameX@base hddPool/vmshared/gameX_vm2
```
## Rolling Back or Deleting Clones

###  Rollback clone to snapshot
```
zfs rollback hddPool/vmshared/gameX_vm1@base
```
### Destroy clone (after unmounting)
```
zfs destroy hddPool/vmshared/gameX_vm1
```
### Set Dataset Properties

### Enable compression (recommended for SSDs)
```
zfs set compression=lz4 nvmePool/root
```
### Enable deduplication (heavy on RAM, use only if enough RAM)
```
zfs set dedup=on hddPool/games
```
### Set readonly (for shared readonly datasets)
```
zfs set readonly=on hddPool/games/gameX
```
### Export & Import Pools (For Maintenance)
```
zpool export nvmePool
zpool export hddPool

zpool import nvmePool
zpool import hddPool
```
### Check Pool & Dataset Status
```
zpool status
zpool list
zfs list
zfs get all nvmePool/root
```

### Scrub Pools (Data Integrity Check)
```
zpool scrub nvmePool
```