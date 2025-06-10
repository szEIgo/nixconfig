{ config, lib, pkgs, plasmaEnabled ? false, ... }: {
  
  home.file = lib.mkMerge [
    (lib.mkIf plasmaEnabled {
      # ".config/kdeglobals".source = ./configs/kdeglobals;
      # ".config/kwinrc".source = ./configs/kwinrulesrc;
    })
    {
      ".config/.gitconfig".source = ./configs/gitconfig; 
      ".zshrc".source = ./configs/zshrc; 
    }
  ];

  home.packages = with pkgs; [
    firefox
    neovim
    git
    htop
  ];

  programs.git.enable = true;

  home.stateVersion = "25.05";
}
