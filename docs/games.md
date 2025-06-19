# Games and Partitions


### Current structure
```
slowPool/                # HDD-based RAIDZ storage
  files/                 # General file storage (mounted)
  game-storage/          # Games (classics, large games)
    baldursgate3/        # Sub-dataset for BG3
    classics/            # Sub-dataset for classic games
```
## Transfer to fastpool
```
sudo zfs snapshot slowPool/game-storage/baldursgate3@snap
sudo zfs send slowPool/game-storage/steam-baldursgate3@snap | sudo zfs receive fastPool/steam-baldursgate3
```