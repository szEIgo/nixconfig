# ./nixos/modules/mothership.nix
{ config, lib, root, ... }:

let
  cfg = config.mothership;
in
{
  # 1. Define the new option we can use in our config
  options.mothership.gpuMode = lib.mkOption {
    type = lib.types.enum [ "amd" "nvidia" "dual-gpu" "headless" ];
    default = "headless";
    description = "Selects the active GPU configuration for Mothership.";
  };

  # 2. Conditionally import the correct hardware module based on the option's value
  #    This is the corrected import block.
  imports = [
    (lib.mkIf (cfg.gpuMode == "amd") (root + "/nixos/modules/hardware/amd-gpu.nix"))
    (lib.mkIf (cfg.gpuMode == "nvidia") (root + "/nixos/modules/hardware/nvidia-gpu.nix"))
    (lib.mkIf (cfg.gpuMode == "dual-gpu") (root + "/nixos/modules/hardware/dual-gpu.nix"))

    # For graphical modes, also import the desktop services
    (lib.mkIf (cfg.gpuMode != "headless") (root + "/nixos/modules/services/plasma.nix"))
    (lib.mkIf (cfg.gpuMode != "headless") (root + "/nixos/modules/services/steam.nix"))
    (lib.mkIf (cfg.gpuMode != "headless") (root + "/nixos/modules/services/sunshine.nix"))
  ];
}
