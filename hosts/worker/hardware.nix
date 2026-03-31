{ config, lib, pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    # USB controllers
    "xhci_pci" "ehci_pci" "uhci_hcd"
    # Storage controllers
    "ahci" "ata_piix" "nvme"
    # USB/SCSI storage
    "usbhid" "usb_storage" "sd_mod" "sr_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
  };

  # Filesystems managed by disko.nix

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}
