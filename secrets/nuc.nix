{ config, pkgs, lib, ... }:

let
  sshDest = "/home/joni/.ssh";
in {
  sops = {
    defaultSopsFile = ./secrets.yaml;

    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };

    secrets = {
      ssh_nuc = {
        path = "${sshDest}/id_ed25519";
        owner = "joni";
        group = "joni";
        mode = "0600";
      };
      k3s_token = {
        path = "/etc/k3s/token";
        owner = "root";
        group = "root";
        mode = "0600";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${sshDest} 0700 joni joni -"
  ];
}
