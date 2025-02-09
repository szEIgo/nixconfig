{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./users.nix
      ./locales.nix
      ./programs.nix
      ./virtualization.nix
      ./zsh.nix
      ./remote/ssh.nix
      ./remote/remote-desktop.nix
      ./desktop-manager/plasma6/plasma.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.shells = with pkgs; [ zsh ];
	
  networking.hostName = "mothership"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.


   services.xserver.enable = true;


  # services.

  # Enable sound.
   #hardware.pulseaudio.enable = true;
  # OR









   security.polkit.enable = true;
   system.stateVersion = "24.11";
}

