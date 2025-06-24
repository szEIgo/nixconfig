{ config, lib, pkgs, ... }: {
  # Kernel modules for virtualization and VFIO
  boot.kernelModules = [
    "kvm-amd"
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
    "vfio_virqfd"
  ];

  # IOMMU and VFIO kernel parameters
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "vfio-pci.ids=1002:ab38,1002:731f,10ec:8125"
  ];

  # Blacklist AMD GPU drivers
  boot.blacklistedKernelModules = [
    "amdgpu"
    "radeon"
  ];

  # Required initrd modules
  boot.initrd.kernelModules = [
    "dm-snapshot"
    "nvidia"
  ];

  # NVIDIA driver configuration
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    open = true;
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };

  # X11 settings to use NVIDIA
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    deviceSection = ''
      Option "Coolbits" "28"
      Option "AllowEmptyInitialConfiguration" "true"
    '';
  };

  # Avoid loading any non-NVIDIA graphics packages
  hardware.graphics.extraPackages = lib.mkForce [ ];
}