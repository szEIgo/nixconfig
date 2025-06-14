{ config, lib, pkgs, plasmaEnabled ? false, ... }: {
  
  imports = [
    ./plasma6.nix
  ];

  home.file = lib.mkMerge [
    {
      "./.gitconfig".source = ./configs/gitconfig;
      ".zshrc".source = ./configs/zshrc;
    }
  ];

  home.packages = with pkgs; [
    firefox
    neovim
    git
    htop
    zsh-powerlevel10k
    oh-my-zsh
  ];
  programs.git.enable = true;
  home.stateVersion = "25.05";
}
