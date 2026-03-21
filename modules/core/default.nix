# Core module: Minimal base for ALL NixOS hosts
# Import this in every NixOS configuration
{ config, lib, pkgs, ... }:

{
  imports = [
    ./nix-settings.nix
    ./locales.nix
    ./users.nix
  ];

  # Console keyboard layout
  console.keyMap = "dk-latin1";

  # Wireless tools — iwctl available if a wifi card is present
  environment.systemPackages = [ pkgs.iwd ];
}
