
# ZFS Maintenance & Management Guide
### Pool & Dataset Naming Overview
```
rpool/                   # Main system pool
  docker/                # Docker storage
  nixos/                 # NixOS system datasets
    home/                # User home
    nix/                 # Nix store
    root/                # Root FS
  vm-pools/              # VM images (multiple datasets)

slowPool/                # HDD-based RAIDZ storage
  files/                 # General file storage (mounted)
  game-storage/          # Games (classics, large games)
    baldursgate3/        # Sub-dataset for BG3
    classics/            # Sub-dataset for classic games
```


## Mounting & Importing Pools

### After Reboot: Load Pools
```
zpool import -a          # Imports all available pools
zfs mount -a             # Mounts all datasets with mountpoints
zfs load-key -a          # Load keys for all encrypted datasets
zpool import -a          # Then import pools
zfs mount -a             # Mount datasets
zfs load-key rpool/nixos/home
zfs mount rpool/nixos/home


```

## Create a snapshot
```
zfs snapshot slowPool/game-storage/baldursgate3@base
zfs clone slowPool/game-storage/baldursgate3@base rpool/vm-pools/baldursgate3_vm1

```
##  Rollback or Remove Clones
```
zfs rollback rpool/vm-pools/baldursgate3_vm1@base
zfs destroy rpool/vm-pools/baldursgate3_vm1
```

## Status & Inspection
```
zpool status
zpool list
zfs list
zfs get all rpool/nixos/home

```

## Scrub Pools (Check Data Integrity)
```
zpool scrub rpool
zpool scrub slowPool
```

## Pool Creation & Basic Setup

### Create NVMe RAID1 pool (example: adata + kingston)
```
zpool create -f nvmePool mirror /dev/nvme0n1 /dev/nvme1n1 \
  ashift=12
```

### Create HDD RAIDZ pool (example: 2 or more HDDs)
``` zpool create -f slowPool raidz1 /dev/sdX /dev/sdY /dev/sdZ \
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
zfs create slowPool/games
zfs create slowPool/vmshared
zfs create slowPool/backups
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
zfs snapshot slowPool/games/gameX@base
```

### Create VM clone from snapshot (independent writable copy)

```
zfs clone slowPool/games/gameX@base slowPool/vmshared/gameX_vm1
zfs clone slowPool/games/gameX@base slowPool/vmshared/gameX_vm2
```
## Rolling Back or Deleting Clones

###  Rollback clone to snapshot
```
zfs rollback slowPool/vmshared/gameX_vm1@base
```
### Destroy clone (after unmounting)
```
zfs destroy slowPool/vmshared/gameX_vm1
```
### Set Dataset Properties

### Enable compression (recommended for SSDs)
```
zfs set compression=lz4 nvmePool/root
```
### Enable deduplication (heavy on RAM, use only if enough RAM)
```
zfs set dedup=on slowPool/games
```
### Set readonly (for shared readonly datasets)
```
zfs set readonly=on slowPool/games/gameX
```
### Export & Import Pools (For Maintenance)
```
zpool export nvmePool
zpool export slowPool

zpool import nvmePool
zpool import slowPool
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