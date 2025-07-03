{ config, pkgs, ... }: {
  imports = [
    ./plasma.nix
    ../common/services.nix
    ../gaming/steam.nix
  ];
}