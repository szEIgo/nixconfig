{ config, lib, pkgs, ... }: {
  imports = [
    # Shared modules
    ../../modules/common/zsh.nix
    ../../modules/common/services.nix

    # Desktop
    ../../modules/desktop/plasma.nix

    # Remote access
    ../../remote/ssh.nix
  ];

  local.ssh = {
    desktop = true;
    passwordAuth = false;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "x250";

  # Laptop power management
  services.thermald.enable = true;
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      START_CHARGE_THRESH_BAT0 = 20;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };
  powerManagement.powertop.enable = true;

  users.defaultUserShell = pkgs.zsh;

  # Required when Home Manager is installed via NixOS module with useUserPackages
  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

  environment.sessionVariables = {
    EDITOR = "vim";
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # Networking
  networking.networkmanager.enable = true;

  # Memory management
  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";

  security.polkit.enable = true;

  # Provide the dconf D-Bus service required by Home Manager's dconf module
  services.dbus.enable = true;
  services.dbus.packages = [ pkgs.dconf ];
  programs.dconf.enable = true;

  system.stateVersion = "25.11";
}
