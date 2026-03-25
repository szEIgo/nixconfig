{ config, lib, pkgs, ... }:
{
  imports = [ ../../modules/common/packages.nix ];

  # Flutter/Android/JDK moved to per-project devShells via direnv
  environment.systemPackages = with pkgs; [
    openvscode-server
    virt-manager
    qemu
    libvirt
    xauth
    amdgpu_top
    kdePackages.yakuake
    kdePackages.kdeconnect-kde
    xwayland-satellite
    kmod
    zfs
    cryptsetup
    moonlight-qt
    podman
    podman-tui
    podman-compose
    dive
    yazi
    zellij
    k9s
    wayvnc
    tigervnc
  ];
  networking.firewall.allowedTCPPorts = [ 5900 ];

  programs = {
    partition-manager.enable = true;
    xwayland.enable = true;
    kdeconnect.enable = true;
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
        zlib
        fuse3
        icu
        nss
        openssl
        curl
        expat
      ];
    };
  };
}
