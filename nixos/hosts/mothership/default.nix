# ./nixos/hosts/mothership/default.nix
# This is now the single, unified configuration for the Mothership machine.
{ root, ... }: {
  imports = [
    # Hardware-specifics
    ./hardware.nix

    # Our new custom module to control GPU modes
    "${root}/nixos/modules/mothership.nix"

    # Shared modules
    "${root}/nixos/modules/common.nix"
    "${root}/nixos/modules/services/libvirt.nix"
    "${root}/nixos/modules/services/podman.nix"
    "${root}/nixos/modules/services/wireguard-server.nix"
    "${root}/home-manager/modules/nixos.nix"
  ];

  networking.hostName = "mothership";

  # --- HEADLESS CONFIGURATION (The Default) ---
  # These are the base settings when mothership.gpuMode is "headless".
  # They will be overridden by the specialisations below.
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "vfio-pci.ids=10de:1f07,10de:10f9,10de:1ada,10de:1adb,1002:ab38,1002:731f"
    "video=efifb:off"
  ];
  boot.blacklistedKernelModules = [ "nouveau" "nvidia" "amdgpu" ];
  hardware.graphics.enable = false;
  services.displayManager.sddm.enable = false;

  # --- SPECIALISATIONS (Your Boot Modes) ---
  # This block creates the different boot menu entries by setting our custom option.
  specialisation = {
    amd = {
      # This imports this whole file again, but sets the gpuMode to "amd"
      imports = [ ./default.nix ];
      mothership.gpuMode = "amd";
      system.nixos.label = "NixOS (AMD GPU)";
    };
    nvidia = {
      imports = [ ./default.nix ];
      mothership.gpuMode = "nvidia";
      system.nixos.label = "NixOS (NVIDIA GPU)";
    };
    dual-gpu = {
      imports = [ ./default.nix ];
      mothership.gpuMode = "dual-gpu";
      system.nixos.label = "NixOS (Dual GPU)";
    };
  };
}
