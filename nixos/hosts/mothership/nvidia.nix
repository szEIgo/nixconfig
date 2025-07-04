# ./nixos/hosts/mothership/nvidia.nix
{ root, ... }: {
  imports = [
    # Inherit everything from the base configuration
    ./default.nix

    # Add modules for a graphical desktop
    "${root}/nixos/modules/services/plasma.nix"
    "${root}/nixos/modules/services/steam.nix"
    "${root}/nixos/modules/services/sunshine.nix"

    # Add the NVIDIA-specific hardware module
    "${root}/nixos/modules/hardware/nvidia-gpu.nix"
  ];

  system.nixos.label = "NixOS (NVIDIA GPU)";
}
