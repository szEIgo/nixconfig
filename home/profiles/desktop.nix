# Desktop profile: GUI applications and desktop environment configs
# Only include this on machines with a display (not servers/Pis)
{ config, lib, pkgs, plasmaEnabled ? false, ... }:

{
  imports = [
    ../hyprland.nix
    ../plasma6.nix
    ../omarchy-theme.nix
  ];

  home.packages = with pkgs;
    [
      firefox
      copyq
    ]
    ++ import ../fonts.nix { inherit pkgs; };

  home.file = {
    ".gitconfig".source = ../configs/gitconfig;
    ".powerlevel10k".source = ../configs/p10k.zsh;
  };
}
