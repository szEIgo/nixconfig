{ config, lib, pkgs, ... }: {
  users.users.joni = {
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" "podman" ];
    shell = pkgs.zsh;
  };

  systemd.tmpfiles.rules = [
    "d /mnt/files 0755 joni  joni  -"
  ];

  users.defaultUserShell = pkgs.zsh;
}
