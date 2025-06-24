{ config, lib, pkgs, ... }: {
  # Kernel modules for AMD and VFIO (to pass through NVIDIA)
  boot.kernelModules = [
    "kvm-amd"
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
    "vfio_virqfd"
    "dm-crypt"
  ];

  # Kernel parameters for IOMMU and VFIO (NVIDIA passed through)
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "amdgpu.runpm=0"
    "vfio-pci.ids=10de:1f07,10de:10f9,10de:1ada,10de:1adb,10ec:8125"
  ];

  # Blacklist NVIDIA-related modules
  boot.blacklistedKernelModules = [
    "nvidia"
    "nouveau"
  ];

  # Initrd modules needed
  boot.initrd.kernelModules = [
    "dm-snapshot"
    "amdgpu"
  ];

  # AMD GPU driver and Vulkan support
  hardware.graphics.extraPackages = with pkgs; [
    amdvlk
  ];

  # X11 configuration for AMD GPU
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    deviceSection = ''
      Option "TearFree" "true"
    '';
  };
}
