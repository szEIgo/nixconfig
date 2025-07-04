# ./nixos/hosts/mothership/amd.nix
{ root, ... }: {
  imports = [
    # Inherit everything from the base configuration
    ./default.nix

    # Add modules for a graphical desktop
    "${root}/nixos/modules/services/plasma.nix"
    "${root}/nixos/modules/services/steam.nix"
    "${root}/nixos/modules/services/sunshine.nix"

    # Add the AMD-specific hardware module
    "${root}/nixos/modules/hardware/amd-gpu.nix"
  ];

  # This label shows up in the boot menu
  system.nixos.label = "NixOS (AMD GPU)";
}
