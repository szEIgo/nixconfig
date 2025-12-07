{ config, lib, pkgs, ... }: {

  boot.kernelModules = [ "kvm-amd" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" "dm-crypt" ];
  
  # Bind NVIDIA GPU and its components to vfio-pci at boot
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "amdgpu.runpm=0"
    "vfio-pci.ids=10de:1f07,10de:10f9,10de:1ada,10de:1adb,10ec:8125" # Update with your IDs
  ];

  hardware.graphics = lib.mkForce {
    enable = true;
    enable32Bit = true;
  };

  # Explicitly blacklist NVIDIA drivers from the host
  boot.blacklistedKernelModules = [ "nvidia" "nouveau" ];
  boot.initrd.kernelModules = [ "dm-snapshot" "amdgpu" ];


  # Configure X server for AMD only
  services.xserver = lib.mkForce {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    deviceSection = ''
      Option "TearFree" "true"
    '';
  };
}
