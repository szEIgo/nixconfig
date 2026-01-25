{ config, lib, pkgs, ... }: {

  boot.kernelModules = [ "kvm-amd" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" "dm-crypt" ];
  
  # Single consolidated kernelParams including virtual EDID
  boot.kernelParams = lib.mkForce [
    "amd_iommu=on"
    "iommu=pt"
    "rd.driver.pre=vfio-pci"
    "amdgpu.runpm=0"
    "vfio-pci.ids=10de:1f07,10de:10f9,10de:1ada,10de:1adb,10ec:8125"
    "modprobe.blacklist=nouveau"
    "rd.driver.blacklist=nouveau"
  ];

  hardware.graphics = lib.mkForce {
    enable = true;
    enable32Bit = true;
  };

  # Explicitly blacklist NVIDIA drivers from the host
  boot.blacklistedKernelModules = [ "nvidia" "nouveau" ];
  boot.initrd.kernelModules = [ "dm-snapshot" "amdgpu" ];


  # Disable X server; use Wayland/Hyprland
  services.xserver = lib.mkForce { enable = false; };

}
