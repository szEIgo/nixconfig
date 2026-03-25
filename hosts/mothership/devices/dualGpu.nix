# /etc/nixos/devices/dualGpu.nix
{ config, lib, pkgs, ... }: {
  # FORCE these lists to override the base configuration
  boot.kernelModules = lib.mkForce ["kvm-amd" "dm-crypt"];
  boot.blacklistedKernelModules = lib.mkForce ["vfio" "nouveau"];

  # Do not require NVIDIA in initrd to avoid modules-shrunk modprobe failures
  boot.initrd.kernelModules = ["dm-snapshot" "amdgpu"];

  # Use mkForce for clarity and to override the base headless config
  hardware.graphics = lib.mkForce {
    enable = true;
    enable32Bit = true;
  };

  # Configure NVIDIA driver
  hardware.nvidia = {
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    open = true;
    powerManagement.enable = false;
  };

  # Disable X server; still select drivers for packaging
  services.xserver = lib.mkForce {
    enable = false;
    videoDrivers = [ "amdgpu" "nvidia" ];
  };

  # Single consolidated kernelParams including NVIDIA DRM modeset for Wayland
  boot.kernelParams = lib.mkForce [
    "amd_iommu=on"
    "iommu=pt"
    "amdgpu.runpm=0"
    "amdgpu.noretry=0"
    "amdgpu.lockup_timeout=1000"
    "amdgpu.gpu_recovery=1"
    "modprobe.blacklist=nouveau"
    "rd.driver.blacklist=nouveau"
    "nvidia_drm.modeset=1"
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "udev.log_level=3"
    "rd.udev.log_level=3"
  ];
}
