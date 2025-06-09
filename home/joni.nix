{ config, lib, pkgs, plasmaEnabled ? false, ... }: {

  
  home.file = lib.mkIf plasmaEnabled {
   # ".config/kdeglobals".source = ./configs/kdeglobals;
   # ".config/kwinrc".source = ./configs/kwinrulesrc;
   .config/.gitconfig.source = ./configs/gitconfig;
  };

  home.packages = [
    pkgs.firefox
    pkgs.neovim
    pkgs.git
    pkgs.htop
  ];

  programs.zsh.enable = true;
  programs.git.enable = true;

  home.stateVersion = "25.05";
}
