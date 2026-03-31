# Declarative disk layout for k3s worker nodes
# Supports both Legacy BIOS and UEFI boot modes
{ config, lib, ... }:

let
  cfg = config.local.worker;
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
  };

  config = {
    disko.devices.disk.main = {
      device = cfg.disk;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          # BIOS boot partition (legacy only, ignored by UEFI)
          boot = lib.mkIf (cfg.bootMode == "legacy") {
            size = "1M";
            type = "EF02";
          };
          # EFI System Partition (UEFI only)
          esp = lib.mkIf (cfg.bootMode == "uefi") {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "fmask=0022" "dmask=0022" ];
            };
          };
          nixos = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              extraArgs = [ "-L" "nixos" ];
            };
          };
        };
      };
    };

    # Bootloader: GRUB for legacy, systemd-boot for UEFI
    boot.loader.grub.enable = cfg.bootMode == "legacy";
    boot.loader.systemd-boot.enable = cfg.bootMode == "uefi";
    boot.loader.systemd-boot.configurationLimit = lib.mkIf (cfg.bootMode == "uefi") 10;
    boot.loader.efi.canTouchEfiVariables = cfg.bootMode == "uefi";
  };
}
