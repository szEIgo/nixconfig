{ config, lib, pkgs, ... }: {
  boot.kernelModules = [ "kvm-amd" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" "dm-crypt" ];
  
  # Bind BOTH GPUs to vfio-pci
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "amdgpu.runpm=0"
    "vfio-pci.ids=10de:1f07,10de:10f9,10de:1ada,10de:1adb,1002:ab38,1002:731f,10ec:8125" # All GPU IDs
  ];

  # Blacklist all graphics drivers from the host
  boot.blacklistedKernelModules = [ "nouveau" "nvidia" "amdgpu" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];

  # This section now fully disables graphics services by providing
  # minimal valid values for required attributes, then disabling the features.
  services.xserver = lib.mkForce {
    enable = false;
  };
  

  
  hardware.graphics = lib.mkForce {
    enable = false;
    enable32Bit = false;
    # Provide a minimal, harmless package to satisfy the evaluator.
    package = pkgs.hello;
    extraPackages = [];
  };

  hardware.opengl = lib.mkForce {
    enable = false;
  };
}