{ config, pkgs, lib, ... }:

let
  sshDest = "/home/joni/.ssh";
  wgDest = "/etc/secrets";
in {
  age.secrets = {
    master = {
      file = ./id_mothership.age;
      path = "/run/agenix/master.id_mothership";
      owner = "root";
      group = "root";
      mode = "0600";
    };

    id_ecdsa = {
      file = ./id_ecdsa.age;
      path = "${sshDest}/id_ecdsa";
      owner = "joni";
      group = "joni";
      mode = "0600";
    };

    mothership = {
      file = ./mothership.age;
      path = "${sshDest}/mothership";
      owner = "joni";
      group = "joni";
      mode = "0600";
    };

    mothership_wg_private = {
      file = ./mothership_wg_private.key.age;
      path = "${wgDest}/mothership_wg_private.key";
      owner = "root";
      group = "root";
      mode = "0600";
    };

  };

  age.identityPaths = [ "/run/agenix/master.id_mothership" ];
}

