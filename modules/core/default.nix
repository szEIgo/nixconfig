# Core module: Minimal base for ALL NixOS hosts
# Import this in every NixOS configuration
{ config, lib, pkgs, ... }:

{
  imports = [
    ./nix-settings.nix
    ./locales.nix
    ./users.nix
  ];
}
