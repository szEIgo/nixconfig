# Main home-manager configuration
# Composes profiles based on hostType
{ config, lib, pkgs, hostType ? "desktop", plasmaEnabled ? false, ... }:

let
  isDesktop = hostType == "desktop";
  isWorkstation = hostType == "workstation" || isDesktop;
  isServer = hostType == "server";
in
{
  imports = [
    # Always include base CLI tools and shell
    ./profiles/base.nix
    ./shell
  ]
  # Development tools for workstations (not servers)
  ++ lib.optionals isWorkstation [ ./profiles/dev.nix ]
  # Desktop environment (Linux desktop only)
  ++ lib.optionals isDesktop [ ./profiles/desktop.nix ];

  # Pass plasmaEnabled to desktop profile
  _module.args.plasmaEnabled = plasmaEnabled;

  home.stateVersion = "25.11";
}