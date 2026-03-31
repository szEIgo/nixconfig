{ config, pkgs, lib, ... }:

{
  sops = {
    defaultSopsFile = ./secrets.yaml;

    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };

    secrets = {
      k3s_token = {
        path = "/etc/k3s/token";
        owner = "root";
        group = "root";
        mode = "0600";
      };
    };
  };
}
