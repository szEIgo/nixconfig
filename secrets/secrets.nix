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
      ssh_id_ecdsa = {
        path = "${sshDest}/id_ecdsa";
        owner = "joni";
        group = "joni";
        mode = "0600";
      };

      ssh_mothership = {
        path = "${sshDest}/mothership";
        owner = "joni";
        group = "joni";
        mode = "0600";
      };

      wireguard_private_key = {
        path = "${wgDest}/mothership_wg_private.key";
        owner = "root";
        group = "systemd-network";
        mode = "0640";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${wgDest} 0750 root systemd-network -"
    "d ${sshDest} 0700 joni joni -"
  ];
}
