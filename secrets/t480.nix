{ config, pkgs, lib, ... }:

let
  sshDest = "/home/joni/.ssh";
  wgDest = "/etc/secrets";
in {
  sops = {
    defaultSopsFile = ./secrets.yaml;

    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };

    secrets = {
      ssh_t480 = {
        path = "${sshDest}/id_ed25519";
        owner = "joni";
        group = "joni";
        mode = "0600";
      };

      wg_t480_private_key = {
        path = "${wgDest}/t480_wg_private.key";
        owner = "root";
        group = "root";
        mode = "0600";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${sshDest} 0700 joni joni -"
    "d ${wgDest} 0750 root root -"
  ];
}
