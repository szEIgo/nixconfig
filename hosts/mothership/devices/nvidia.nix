# /etc/nixos/devices/nvidia.nix
{ config, lib, pkgs, ... }: {
  # FORCE these lists to override the base configuration
  boot.kernelModules = lib.mkForce [ "kvm-amd" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];
  # Single consolidated kernelParams including virtual EDID
  boot.kernelParams = lib.mkForce [
    "amd_iommu=on"
    "iommu=pt"
    "vfio-pci.ids=1002:ab38,1002:731f,10ec:8125"
#  "drm.edid_firmware=HDMI-A-1:edid/virtual-2048x1332.bin"
#    "video=HDMI-A-1:2048x1332R@60e"
  ];
  boot.blacklistedKernelModules = lib.mkForce [ "amdgpu" "radeon" ];
  
  # This can be left as-is, as it's not a list being merged
  boot.initrd.kernelModules = [ "dm-snapshot" "nvidia" ];

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

  # Disable X server; use Wayland/Hyprland
  services.xserver = lib.mkForce { enable = false; };

}