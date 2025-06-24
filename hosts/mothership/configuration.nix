{ config, lib, pkgs, ... }: {
  imports = [
    ./hardware.nix
    ./packages.nix
    ./devices/default.nix
    ./devices/wireguard-server.nix
    ../../modules/common/locales.nix
    ../../modules/common/users.nix
    ../../modules/common/zfs.nix
    ../../modules/virtualization/libvirt.nix
    ../../modules/virtualization/podman.nix

    ../../modules/common/services.nix
    ../../modules/gaming/steam.nix
    ../../remote/ssh.nix
    ../../modules/desktop/plasma.nix
    ../../modules/desktop/hyprland.nix

  ];
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" "ntfs" ];
  boot.zfs.requestEncryptionCredentials = true;
  boot.initrd.luks.devices."cryptroot".device =
    "/dev/disk/by-uuid/2191f348-040d-42e3-9caf-c43b86f9a6df";
  boot.kernel.sysctl."kernel.watchdog" = 1;

  boot.kernelPackages = pkgs.linuxPackages_6_14;
  boot.crashDump.enable = true;

  users.defaultUserShell = pkgs.zsh;
  virtualisation.containers.enable = true;

  networking.hostName = "mothership";
  networking.hostId = "6d539f2f";

  specialisation = {
    nvidia.configuration = {
      system.nixos.tags = [ "nvidia" ];
      imports = [ ./devices/nvidia.nix ];
    };

    amd.configuration = {
      system.nixos.tags = [ "amd" ];
      imports = [ ./devices/amd.nix ];
    };

    #default.configuration = {
    #  system.nixos.tags = ["default"];
    #  imports = [./devices/default.nix];
    #};

    headless.configuration = {
      system.nixos.tags = [ "headless" ];
      imports = [ ./devices/headless.nix ];
    };
  };

  services.xserver.enable = true;
  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";

  environment.sessionVariables = {
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
  };

  security.polkit.enable = true;

  system.stateVersion = "25.05";
}
