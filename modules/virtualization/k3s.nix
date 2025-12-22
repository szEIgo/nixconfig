{ config, pkgs, ... }:

{
  systemd.tmpfiles.rules = [
    # Point common sbin paths to NixOS zfs binary
    "L /sbin/zfs - - - - /run/current-system/sw/bin/zfs"
    "L /usr/sbin/zfs - - - - /run/current-system/sw/bin/zfs"
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];
  

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags =
      [ "--disable traefik" "--disable servicelb" "--disable local-storage" ];
  };

  networking.firewall.allowedTCPPorts = [ 6443 30080 30443 ];
  networking.firewall.allowedUDPPorts = [ 8472 ];

}
