# ./home-manager/joni.nix
# Your main user definition, shared across all systems.
{ pkgs, root, ... }: {
  imports = [
    # Import modularized configurations
    "${root}/home-manager/modules/cli/default.nix"
    "${root}/home-manager/modules/gui/default.nix"
  ];

  # Set user details, can be overridden by specific host configs
  home.username = "joni";
  home.homeDirectory = "/home/joni";
  home.stateVersion = "25.05";

  # Shared CLI packages for all systems (NixOS, macOS, Android)
  home.packages = with pkgs; [
    eza
    bat
    htop
    btop
    zellij
    neovim
    helix
    age
    keychain
    ripgrep
    fd
    jq
    zoxide
    fzf
  ];

  # Link dotfiles from the central dotfiles directory
  home.file.".gitconfig".source =
    "${root}/home-manager/dotfiles/git/.gitconfig";
  home.file.".p10k.zsh".source = "${root}/home-manager/dotfiles/p10k/.p10k.zsh";

  programs.git.enable = true; # Manages .gitconfig through options if you prefer
}
