# /etc/nixos/devices/dualGpu.nix
{ config, lib, pkgs, ... }: {
  # FORCE these lists to override the base configuration
  boot.kernelModules = lib.mkForce ["kvm-amd" "dm-crypt"];
  boot.kernelParams = lib.mkForce [
    "amd_iommu=on" 
    "iommu=pt" 
    "amdgpu.runpm=0" 
    "modprobe.blacklist=nouveau" 
    "rd.driver.blacklist=nouveau"
  ];
  boot.blacklistedKernelModules = lib.mkForce ["vfio" "nouveau"];

  # This can be left as-is
  boot.initrd.kernelModules = ["dm-snapshot" "amdgpu" "nvidia"];

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

  # Tell X server to use both drivers
  services.xserver = lib.mkForce {
    enable = true;
    videoDrivers = ["amdgpu" "nvidia"];
    deviceSection = ''
      Option "TearFree" "true"
    '';
  };
}
