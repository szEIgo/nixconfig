# nix-on-droid configuration for Android
# Deploy: nix-on-droid switch --flake ~/nixconfig#default
{ config, lib, pkgs, ... }:

{
  # Essential system packages available outside home-manager
  environment.packages = with pkgs; [
    vim
    git
    openssh
    procps
    killall
    diffutils
    findutils
    util-linux
    tzdata
    hostname
    man
    gnugrep
    gnutar
    gzip
    unzip
    curl
    wget
  ];

  environment.etcBackupExtension = ".bak";

  # Use zsh as default shell
  user.shell = "${pkgs.zsh}/bin/zsh";

  # Nix settings
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  time.timeZone = "Europe/Copenhagen";

  # Terminal styling — set TERM properly for color support
  terminal.colors = {
    foreground = "#fcfcfc";
    background = "#000000";
  };

  system.stateVersion = "25.11";
}
