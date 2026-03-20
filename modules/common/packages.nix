# Common system packages for NixOS desktops/workstations
# CLI tools are now in home/profiles/base.nix (home-manager)
# This is for NixOS system-level packages only
{ config, lib, pkgs, ... }: {
  # Linux-only system packages (cross-platform tools are in home/joni.nix)
  environment.systemPackages = with pkgs; [
    net-tools
    pciutils
    usbutils
    gptfdisk
    parted
    woeusb-ng
    haskellPackages.Xauth
    kmod
    android-tools
    qtscrcpy
  ];

}
