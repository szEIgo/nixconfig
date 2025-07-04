# ./nixos/modules/hardware/dual-gpu.nix
{ config, lib, pkgs, ... }: {
  # Override settings from the headless default
  boot.kernelParams = lib.mkForce [ "amd_iommu=on" "iommu=pt" ];
  boot.blacklistedKernelModules = lib.mkForce [ "vfio_pci" ]; # Don't use VFIO
  boot.initrd.kernelModules = [ "amdgpu" "nvidia" ];

  hardware.graphics = {
    enable = lib.mkForce true;
    enable32Bit = lib.mkForce true;
    extraPackages = with pkgs; [ amdvlk ];
  };

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    open = true;
    modesetting.enable = true;
    powerManagement.enable = false;
  };

  services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];
}
