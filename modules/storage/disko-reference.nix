# Disko Reference Configuration for Mothership
#
# This file documents the current ZFS storage layout declaratively.
# It is NOT applied automatically - it serves as:
#   1. Documentation of the current disk/pool layout
#   2. Reference for future reinstalls or new hosts
#   3. Template for disko-based provisioning
#
# To actually apply this config on a fresh install:
#   nix run github:nix-community/disko -- --mode disko ./disko-reference.nix
#
# Current layout (as of March 2026):
#   nvme0n1 (ADATA 1TB) - Boot + LUKS encrypted rpool
#   nvme1n1 (Kingston 1TB) - fastPool + slowPool cache/log
#   sda, sdb (2x Seagate 6TB) - slowPool data drives

{ lib, ... }:

{
  disko.devices = {
    disk = {
      # Primary NVMe - Boot drive with LUKS-encrypted ZFS
      nvme0n1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-ADATA_SX8200PNP_2J2020025721";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "2G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "fmask=0022" "dmask=0022" ];
              };
            };
            cryptroot = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                # UUID: 2191f348-040d-42e3-9caf-c43b86f9a6df
                settings.allowDiscards = true;
                content = {
                  type = "zfs";
                  pool = "rpool";
                };
              };
            };
          };
        };
      };

      # Secondary NVMe - fastPool data + slowPool cache/log
      nvme1n1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KINGSTON_SA2000M81000G_50026B728253C4D3";
        content = {
          type = "gpt";
          partitions = {
            # L2ARC cache for slowPool (~294GB)
            slowpool-cache = {
              size = "294G";
              content = {
                type = "zfs";
                pool = "slowPool";
                # Note: This is added as cache, not as a regular vdev
              };
            };
            # fastPool main data (~540GB)
            fastpool-data = {
              size = "540G";
              content = {
                type = "zfs";
                pool = "fastPool";
              };
            };
            # SLOG for slowPool (~98GB)
            slowpool-log = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "slowPool";
                # Note: This is added as log (SLOG), not as a regular vdev
              };
            };
          };
        };
      };

      # First HDD for slowPool
      sda = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ST6000VN0033-2EE110_ZADAVRBT";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "slowPool";
              };
            };
          };
        };
      };

      # Second HDD for slowPool
      sdb = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ST6000VN0033-2EE110_ZADAVRP5";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "slowPool";
              };
            };
          };
        };
      };
    };

    zpool = {
      # Root pool - LUKS encrypted, contains OS and user data
      rpool = {
        type = "zpool";
        mode = ""; # Single device (on LUKS)
        rootFsOptions = {
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
          atime = "off";
          mountpoint = "none";
        };
        datasets = {
          "nixos" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "nixos/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy";
          };
          "nixos/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options.mountpoint = "legacy";
          };
          "nixos/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "legacy";
          };
          "docker" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/docker";
          };
          "vm-pools" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "vm-pools/golden-image" = {
            type = "zfs_volume";
            size = "200G";
            content = {
              type = "filesystem";
              format = "ntfs";
            };
          };
          "vm-pools/windows-amd" = {
            type = "zfs_volume";
            size = "200G";
          };
          "vm-pools/windows-nvidia" = {
            type = "zfs_volume";
            size = "200G";
          };
        };
      };

      # Fast pool - Plain ZFS on NVMe for performance-critical workloads
      fastPool = {
        type = "zpool";
        mode = ""; # Single device
        rootFsOptions = {
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
          atime = "off";
          mountpoint = "/fastPool";
        };
        datasets = {
          "k3s" = {
            type = "zfs_fs";
            mountpoint = "/fastPool/k3s";
          };
          # Note: k3s PVC datasets are created dynamically by zfs-provisioner
          "steam-baldursgate3" = {
            type = "zfs_fs";
            options.mountpoint = "none"; # Mounted via virtiofs to VMs
          };
        };
      };

      # Slow pool - Encrypted ZFS on HDDs with NVMe cache/log
      # Uses native ZFS encryption (aes-256-gcm)
      slowPool = {
        type = "zpool";
        mode = ""; # Stripe of two disks (NOT mirror)
        rootFsOptions = {
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
          atime = "off";
          mountpoint = "none";
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          keylocation = "prompt";
        };
        # Note: cache (L2ARC) and log (SLOG) are on nvme1n1p1 and nvme1n1p3
        datasets = {
          "files" = {
            type = "zfs_fs";
            mountpoint = "/mnt/files";
          };
          "game-storage" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "game-storage/battle.net" = {
            type = "zfs_fs";
            options.mountpoint = "none"; # Mounted to VMs
          };
          "game-storage/classic" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "game-storage/pathOfExile2" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "game-storage/steam-baldursgate3" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "k3s" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          # Note: k3s PVC datasets are created dynamically by zfs-provisioner
        };
      };
    };
  };
}
