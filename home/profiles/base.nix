# Base profile: Core CLI tools for ALL platforms (Linux, macOS, servers)
# This is the foundation that every machine should have
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Shell essentials
    zsh
    zsh-powerlevel10k
    oh-my-zsh
    fzf
    zoxide
    eza
    bat
    fd
    ripgrep
    jq
    tree
    ncdu
    dust
    tmux

    # Git & version control
    git
    gh

    # System monitoring
    htop
    btop

    # Network tools
    wget
    curl

    # File management
    yazi

    # Editor
    helix
    neovim
  ];

  # Core programs enabled via home-manager
  programs.git.enable = true;

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

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

  programs.zellij = {
    enable = true;
    enableZshIntegration = false;
    settings = {
      show_startup_tips = false;
      default_layout = "compact";
      default_shell = "zsh";
    };
  };
}
