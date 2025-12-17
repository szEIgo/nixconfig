{ config, lib, pkgs, ... }: {
  imports = [ ../../modules/common/packages.nix ];

  environment.systemPackages = with pkgs; [
    openvscode-server
    virt-manager
    qemu
    libvirt
    xorg.xauth
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
  ];

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

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      settings = {
        default-cache-ttl = 1800;
        max-cache-ttl = 7200;
      };
      pinentryPackage = pkgs.pinentry-tty;
    };
  };
}
