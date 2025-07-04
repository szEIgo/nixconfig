# ./nixos/modules/services/steam.nix
{ pkgs, ... }: {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  programs.gamemode.enable = true;
  hardware.steam-hardware.enable = true;
}
