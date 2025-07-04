# ./nixos/hosts/mothership/hardware.nix
{ config, lib, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" "dm-crypt" ];

  # ZFS Support
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs.autoScrub.enable = true;

  fileSystems."/" = { device = "rpool/nixos/root"; fsType = "zfs"; };
  fileSystems."/nix" = { device = "rpool/nixos/nix"; fsType = "zfs"; };
  fileSystems."/home" = { device = "rpool/nixos/home"; fsType = "zfs"; };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/8B9A-049B";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # CPU microcode
  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
