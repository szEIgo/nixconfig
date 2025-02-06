{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./users.nix
      ./locales.nix
      ./ssh.nix
      ./services.nix
      ./programs.nix
      ./virtualization.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.kernelPackages = pkgs.linuxPackages-rt_latest;
  boot.loader.efi.canTouchEfiVariables = true;
	

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

