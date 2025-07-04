# /etc/nixos/hosts/android/default.nix
{ config, lib, pkgs, ... }:
{
  environment.packages = with pkgs; [
    vim
    procps
    killall
    diffutils
    findutils
    utillinux
    tzdata
    hostname
    git
    openssh
  ];

  environment.etcBackupExtension = ".bak";
  system.stateVersion = "24.05"; # Updated to match your flake
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  time.timeZone = "Europe/Copenhagen";
}
