{ config, lib, pkgs, ... }: {
  # Enable essential modules for virtualization and disk
  boot.kernelModules = [
    "kvm-amd"
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
    "vfio_virqfd"
    "dm_mod"
    "dm_mirror"
    "dm_snapshot"
    "dm_thin_pool"
  ];

  # Kernel parameters for IOMMU and GPU passthrough
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "amdgpu.runpm=0"
    "vfio-pci.ids=10de:1f07,10de:10f9,10de:1ada,10de:1adb,1002:ab38,1002:731f,10ec:8125"
  ];

  # Blacklist all GPU drivers
  boot.blacklistedKernelModules = [
    "amdgpu"
    "nouveau"
    "nvidia"
  ];

  # Prevent the base config from loading these modules
  boot.initrd.kernelModules = lib.mkForce [ ];

  # Disable X11 and Wayland
  services.xserver.enable = lib.mkForce false;

  # Ensure no GPU drivers are selected
  services.xserver.videoDrivers = lib.mkForce [ ];
  hardware.opengl.enable = lib.mkForce false;
  hardware.nvidia = {
    modesetting.enable = lib.mkForce false;
    powerManagement.enable = lib.mkForce false;
    powerManagement.finegrained = lib.mkForce false;
    open = lib.mkForce false;
  };

  # Prevent loading any graphics packages
  hardware.graphics.extraPackages = lib.mkForce [ ];

  # Optional: Prevent desktop environments from starting
  environment.sessionVariables = {
    XDG_SESSION_TYPE = "tty";
  };
}
