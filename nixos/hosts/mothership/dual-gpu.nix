# ./nixos/hosts/mothership/dual-gpu.nix
{ root, ... }: {
  imports = [
    # Inherit everything from the base configuration
    ./default.nix

    # Add modules for a graphical desktop
    "${root}/nixos/modules/services/plasma.nix"
    "${root}/nixos/modules/services/steam.nix"
    "${root}/nixos/modules/services/sunshine.nix"

    # Add the dual-GPU-specific hardware module
    "${root}/nixos/modules/hardware/dual-gpu.nix"
  ];

  system.nixos.label = "NixOS (Dual GPU)";
}
