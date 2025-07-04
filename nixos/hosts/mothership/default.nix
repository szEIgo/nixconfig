# ./nixos/hosts/mothership/default.nix
# This is the base headless system configuration.
{ config, pkgs, root, ... }: {
  imports = [
    # Hardware-specifics
    ./hardware.nix

    # Shared modules
    "${root}/nixos/modules/common.nix"
    "${root}/nixos/modules/services/libvirt.nix"
    "${root}/nixos/modules/services/podman.nix"
    "${root}/nixos/modules/services/wireguard-server.nix"

    # Home Manager integration
    "${root}/home-manager/modules/nixos.nix"
  ];

  networking.hostName = "mothership";
  networking.hostId = "6d539f2f";

  # Use a recent kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # --- HEADLESS CONFIGURATION ---
  # By default, this system boots without a graphical interface.
  # We bind all GPUs to vfio-pci for virtual machines.
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    # Bind both AMD and NVIDIA GPUs to vfio-pci
    "vfio-pci.ids=10de:1f07,10de:10f9,10de:1ada,10de:1adb,1002:ab38,1002:731f"
    "video=efifb:off"
  ];

  # Blacklist graphics drivers to ensure they don't claim the devices
  boot.blacklistedKernelModules = [ "nouveau" "nvidia" "amdgpu" ];

  # Ensure graphical services are disabled
  services.xserver.enable = false;
  services.displayManager.sddm.enable = false;
  hardware.graphics.enable = false;
}
