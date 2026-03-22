# /etc/nixos/devices/nvidia.nix
{ config, lib, pkgs, ... }: {
  # FORCE these lists to override the base configuration
  boot.kernelModules = lib.mkForce [ "kvm-amd" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];
  # Single consolidated kernelParams including NVIDIA DRM modeset for Wayland
  boot.kernelParams = lib.mkForce [
    "amd_iommu=on"
    "iommu=pt"
    "rd.driver.pre=vfio-pci"
    "vfio-pci.ids=1002:ab38,1002:731f,10ec:8125"
    "nvidia_drm.modeset=1"
    "modprobe.blacklist=nouveau"
    "rd.driver.blacklist=nouveau"
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "udev.log_level=3"
    "rd.udev.log_level=3"
  ];
  boot.blacklistedKernelModules = lib.mkForce [ "amdgpu" "radeon" "nouveau" ];
  
  # Avoid requiring NVIDIA in initrd; load later if present
  boot.initrd.kernelModules = [ "dm-snapshot" ];

  # Configure NVIDIA driver
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    open = true;
    modesetting.enable = true;
    powerManagement.enable = false;
  };

  # Use mkForce to ensure graphics are fully enabled
  hardware.graphics = lib.mkForce {
    enable = true;
    enable32Bit = true;
    extraPackages = [];
  };

  # Disable X server; still select NVIDIA driver for packaging
  services.xserver = lib.mkForce {
    enable = false;
    videoDrivers = [ "nvidia" ];
  };


}