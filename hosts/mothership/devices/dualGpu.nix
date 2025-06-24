{ config, lib, pkgs, ... }: {

  boot.kernelModules = ["kvm-amd" "dm-crypt"];
  boot.kernelParams = [
    "amd_iommu=on" 
    "iommu=pt" 
    "amdgpu.runpm=0" 
    # Ensure nouveau is blacklisted if you're using the proprietary NVIDIA driver
    "modprobe.blacklist=nouveau" 
    "rd.driver.blacklist=nouveau"
  ];
  boot.blacklistedKernelModules = ["vfio" "nouveau"];
  boot.initrd.kernelModules = ["dm-snapshot" "amdgpu" "nvidia"]; # Add nvidia here

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Load graphics packages for both
  hardware.graphics.extraPackages = with pkgs; [ amdvlk ];

  # Configure NVIDIA driver
  hardware.nvidia = {
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    open = true; # Use open-source kernel modules
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