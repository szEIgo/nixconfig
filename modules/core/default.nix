# Core module: Minimal base for ALL NixOS hosts
# Import this in every NixOS configuration
{ config, lib, pkgs, ... }:

let
  nixconfig-plymouth-theme = pkgs.stdenvNoCC.mkDerivation {
    pname = "nixconfig-plymouth-theme";
    version = "1.0";
    src = ./plymouth-theme;
    nativeBuildInputs = [ pkgs.imagemagick ];
    buildPhase = ''
      # Generate progress bar images
      convert -size 300x6 xc:'#400000' bar-bg.png
      convert -size 300x6 xc:'#FF0000' bar-fill.png
    '';
    installPhase = ''
      mkdir -p $out/share/plymouth/themes/nixconfig
      cp $src/nixconfig.plymouth $out/share/plymouth/themes/nixconfig/
      cp $src/nixconfig.script $out/share/plymouth/themes/nixconfig/
      cp $src/logo.png $out/share/plymouth/themes/nixconfig/
      cp bar-bg.png $out/share/plymouth/themes/nixconfig/
      cp bar-fill.png $out/share/plymouth/themes/nixconfig/
    '';
  };
in
{
  imports = [
    ./nix-settings.nix
    ./locales.nix
    ./users.nix
  ];

  # Boot splash with custom Plymouth theme
  boot.plymouth = {
    enable = true;
    theme = "nixconfig";
    themePackages = [ nixconfig-plymouth-theme ];
  };
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "udev.log_level=3"
    "rd.udev.log_level=3"
  ];


  # Wireless tools — iwctl available if a wifi card is present
  environment.systemPackages = with pkgs; [ iwd gnumake ];
}

