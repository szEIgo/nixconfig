{ config, lib, pkgs, plasmaEnabled ? false, ... }: {

  
  home.file = lib.mkMerge [
    (lib.mkIf plasmaEnabled {
      # Conditional files (only if Plasma is enabled)
      # ".config/kdeglobals".source = ./configs/kdeglobals;
      # ".config/kwinrc".source = ./configs/kwinrulesrc;
    })
    {
      # Always-present files
      ".config/.gitconfig".source = ./configs/gitconfig;
      ".zshrc".source = ./configs/zshrc;
      #"./.zshrc".source = ./configs/zshrc;
      
    }
  ];

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
