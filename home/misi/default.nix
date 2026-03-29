# Misi's home-manager configuration
# Starter setup for a Linux user with k3s worker access
{ config, lib, pkgs, ... }:

{
  imports = [
    ./shell.nix
  ];

  home.packages = with pkgs; [
    # Core CLI tools
    git
    htop
    btop
    wget
    ripgrep
    jq
    fd
    eza
    bat
    tree
    tmux
    watch
    vim
    helix

    # Shell
    zsh
    zsh-powerlevel10k

    # Kubernetes
    kubectl
    k9s

    # Networking
    nmap
    curl
  ];

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Misi";
        # TODO: Set email
        # email = "misi@example.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
    };
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
    themes = {
      autumn_night_transparent = {
        "inherits" = "autumn_night";
        "ui.background" = { };
      };
    };
  };

  home.username = "misi";
  home.homeDirectory = "/home/misi";
  home.stateVersion = "25.11";
}
