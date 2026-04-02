# Declarative disk layout for k3s fleet nodes
# Supports both Legacy BIOS and UEFI boot modes
# Uses ZFS for data integrity (checksumming, compression, snapshots)
{ config, lib, ... }:

let
  cfg = config.local.worker;
  isLegacy = cfg.bootMode == "legacy";
  isUefi = cfg.bootMode == "uefi";
in {
  options.local.worker = {
    bootMode = lib.mkOption {
      type = lib.types.enum [ "legacy" "uefi" ];
      default = "legacy";
      description = "Boot mode: legacy (BIOS/MBR/GRUB) or uefi (GPT/systemd-boot)";
    };
    disk = lib.mkOption {
      type = lib.types.str;
      default = "/dev/sda";
      description = "Target disk device";
    };
    k3sRole = lib.mkOption {
      type = lib.types.enum [ "agent" "server" ];
      default = "agent";
      description = "k3s role: agent (worker) or server (control plane)";
    };
    nodeSize = lib.mkOption {
      type = lib.types.enum [ "small" "medium" "large" ];
      default = "small";
      description = "Node resource tier for scheduling (small/medium/large)";
    };
  };

  config = {
    disko.devices.disk.main = {
      device = cfg.disk;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          # BIOS: small embed area for GRUB stage 1
          grub-mbr = lib.mkIf isLegacy {
            size = "1M";
            type = "EF02";
          };
          boot = {
            size = "512M";
            type = if isUefi then "EF00" else "8300";
            content = {
              type = "filesystem";
              format = if isUefi then "vfat" else "ext4";
              mountpoint = "/boot";
              mountOptions = lib.mkIf isUefi [ "fmask=0022" "dmask=0022" ];
            };
          };
          # ZFS pool spanning remaining disk
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };
    };

    disko.devices.zpool.rpool = {
      type = "zpool";
      options = {
        ashift = "12";
        autotrim = "on";
      };
      rootFsOptions = {
        compression = "zstd";
        acltype = "posixacl";
        xattr = "sa";
        dnodesize = "auto";
        mountpoint = "none";
        canmount = "off";
      };
      datasets = {
        "nixos" = {
          type = "zfs_fs";
          mountpoint = "/";
          options.mountpoint = "legacy";
        };
        "nixos/nix" = {
          type = "zfs_fs";
          mountpoint = "/nix";
          options.mountpoint = "legacy";
        };
        "nixos/var" = {
          type = "zfs_fs";
          mountpoint = "/var";
          options.mountpoint = "legacy";
        };
        # Separate dataset for k3s data (etcd on carriers, containerd on all)
        "nixos/k3s" = {
          type = "zfs_fs";
          mountpoint = "/var/lib/rancher";
          options.mountpoint = "legacy";
          options."com.sun:auto-snapshot" = "true";
        };
        # Persistent state that survives impermanence root rollback
        "persist" = {
          type = "zfs_fs";
          mountpoint = "/persist";
          options.mountpoint = "legacy";
        };
      };
    };

    # Bootloader — disko sets GRUB device automatically from the EF02 partition
    boot.loader.grub = lib.mkIf isLegacy {
      enable = true;
      zfsSupport = true;
    };
    boot.loader.systemd-boot.enable = isUefi;
    boot.loader.systemd-boot.configurationLimit = lib.mkIf isUefi 10;
    boot.loader.efi.canTouchEfiVariables = isUefi;

    # ZFS support
    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs.forceImportRoot = false;

    # Generate a stable hostId from the hostname (required for ZFS)
    networking.hostId = builtins.substring 0 8 (
      builtins.hashString "sha256" config.networking.hostName
    );
  };
}
