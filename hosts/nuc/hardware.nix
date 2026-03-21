# Hardware configuration for Intel NUC
#
# TODO: Replace this with the output of `nixos-generate-config --show-hardware-config`
#       run on the actual NUC hardware. The filesystem and boot device UUIDs below
#       are placeholders.
{ config, lib, pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./network.nix
  ];

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
  };

  # TODO: Update these to match the actual NUC disk layout after install.
  # These are placeholders — run `nixos-generate-config` on the NUC and
  # copy the fileSystems / swapDevices sections here.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}
