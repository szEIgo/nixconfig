{ config, lib, pkgs, plasmaEnabled ? false, ... }: {

  imports = [
    ./plasma6.nix
    ./zsh.nix
  ];

  home.file = lib.mkMerge [{
    "./.gitconfig".source = ./configs/gitconfig;
    #    ".zshrc".source = ./configs/zshrc;
    ".powerlevel10k".source = ./configs/p10k.zsh;
  }];

  home.packages = with pkgs; [
    firefox
    neovim
    git
    htop
    zsh-powerlevel10k
    oh-my-zsh
  ];
  programs.git.enable = true;
  programs.zoxide.enable = true;
  programs.zoxide.enableZshIntegration = true;
  programs.helix = {
    enable = true;
    settings = {
      theme = "autumn_night_transparent";
      editor.cursor-shape = {
        normal = "block";
        insert = "bar";
        select = "underline";
      };
    };
    languages.language = [{
      name = "nix";
      auto-format = true;
      formatter.command = "${pkgs.nixfmt-classic}/bin/nixfmt";
    }];
    themes = {
      autumn_night_transparent = {
        "inherits" = "autumn_night";
        "ui.background" = { };
      };
    };
  };

  home.stateVersion = "25.05";
}
