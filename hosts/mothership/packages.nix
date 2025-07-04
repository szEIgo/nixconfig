{ config, lib, pkgs, ... }: {
  imports = [ ../../modules/common/packages.nix ];

  environment.systemPackages = with pkgs; [
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
    ghostty
    yazi
    zellij
    k9s
    openssl
    kubernetes-helm
    nushell
  ];

  programs = {
    partition-manager.enable = true;
    xwayland.enable = true;
    kdeconnect.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}
