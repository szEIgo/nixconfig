# ./nixos/modules/hardware/nvidia-gpu.nix
{ config, lib, pkgs, ... }: {
  # Override settings from the headless default
  boot.kernelParams = lib.mkForce [
    "amd_iommu=on"
    "iommu=pt"
    # Bind only the AMD card to vfio, let nvidia claim its card
    "vfio-pci.ids=1002:ab38,1002:731f"
  ];
  boot.blacklistedKernelModules = lib.mkForce [ "amdgpu" ];
  boot.initrd.kernelModules = [ "nvidia" ];

  hardware.graphics = {
    enable = lib.mkForce true;
    enable32Bit = lib.mkForce true;
  };

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    open = true;
    modesetting.enable = true;
    powerManagement.enable = false;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
}
