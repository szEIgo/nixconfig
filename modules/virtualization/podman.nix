{ config, pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;

    dockerCompat = true;
    defaultNetwork.settings = {
      dns_enabled = true;
    };

    extraPackages = with pkgs; [ podman-compose ];

  };

  fileSystems."/var/lib/docker" = {
    device = "rpool/docker";
    fsType = "zfs";
  };
}
