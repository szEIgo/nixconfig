{ config, lib, pkgs, ... }: {

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

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
