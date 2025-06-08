{ config, pkgs, ... }:

{
  home.username = "joni";
  home.homeDirectory = "/home/joni";

  home.packages = [
    pkgs.firefox
    pkgs.neovim
    pkgs.git
    pkgs.htop
  ];

  programs.zsh.enable = true;
  programs.git.enable = true;

  # Home Manager required
  home.stateVersion = "24.05";
}
