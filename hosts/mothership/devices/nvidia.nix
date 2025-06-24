{ config, lib, pkgs, ... }: {
  boot.kernelModules = [ "kvm-amd" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];
  
  # Bind AMD GPU to vfio-pci
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "vfio-pci.ids=1002:ab38,1002:731f,10ec:8125" # Update with your AMD IDs
  ];

  # Blacklist AMD drivers
  boot.blacklistedKernelModules = [ "amdgpu" "radeon" ];
  boot.initrd.kernelModules = [ "dm-snapshot" "nvidia" ];

  # Configure NVIDIA driver
 hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    open = true;
    modesetting.enable = true;
    powerManagement.enable = false;
  };

  hardware.graphics = lib.mkForce {
    enable = true;
    enable32Bit = true;
    extraPackages = [];
  };

  # Configure X server for NVIDIA only
  services.xserver = lib.mkForce {
    enable = true;
    videoDrivers = [ "nvidia" ];
    deviceSection = ''
      Option "Coolbits" "28"
      Option "AllowEmptyInitialConfiguration" "true"
    '';
  };
}