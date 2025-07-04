´# ./nixos/modules/hardware/amd-gpu.nix
{ lib, pkgs, ... }: {
  # Override settings from the headless default
  boot.kernelParams = lib.mkForce [
    "amd_iommu=on"
    "iommu=pt"
    # Bind only the NVIDIA card to vfio, let amdgpu claim its card
    "vfio-pci.ids=10de:1f07,10de:10f9,10de:1ada,10de:1adb"
  ];
  boot.blacklistedKernelModules = lib.mkForce [ "nvidia" "nouveau" ];
  boot.initrd.kernelModules = [ "amdgpu" ];

  hardware.graphics = {
    enable = lib.mkForce true;
    enable32Bit = lib.mkForce true;
    extraPackages = with pkgs; [ amdvlk ];
  };

  services.xserver.videoDrivers = [ "amdgpu" ];
}
