{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/common/packages.nix
  ];
  

  environment.systemPackages = with pkgs; [
    virt-manager
    qemu
    libvirt
    xorg.xauth
    amdgpu_top
    kdePackages.yakuake
    xwayland-satellite
    kmod
    zfs
    cryptsetup
    moonlight-qt
    podman
    podman-tui
    podman-compose
    dive
  ];
  
  programs = {
    partition-manager.enable = true;
    xwayland.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}
