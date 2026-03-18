{ config, pkgs, ... }:

{
  # Podman container runtime with ZFS storage
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;  # Provides docker CLI alias
    defaultNetwork.settings = {
      dns_enabled = true;
    };
    extraPackages = with pkgs; [ podman-compose ];
  };

  # Container storage configuration (Podman with ZFS backend)
  virtualisation.containers.storage.settings = {
    storage = {
      driver = "zfs";
      graphroot = "/var/lib/containers/storage";
      runroot = "/run/containers/storage";
      options.zfs = {
        fsname = "rpool/podman";
        mountopt = "nodev";
      };
    };
  };
}
