{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
    ./packages.nix
    ./devices/default.nix
    ../../modules/common/locales.nix
    ../../modules/common/users.nix
    ../../modules/common/zfs.nix
    ../../modules/common/virtualization.nix
    ../../modules/common/services.nix
    ../../modules/gaming/steam.nix
    ../../remote/ssh.nix
    ../../modules/desktop/plasma.nix
    ../../modules/desktop/hyprland.nix

    
  ];
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_6_14;

  
  users.defaultUserShell = pkgs.zsh;

  networking.hostName = "mothership";

  specialisation = {
    nvidia.configuration = {
      system.nixos.tags = ["nvidia"];
      imports = [./devices/nvidia.nix];
    };

    amd.configuration = {
      system.nixos.tags = ["amd"];
      imports = [./devices/amd.nix];
    };

    #default.configuration = {
    #  system.nixos.tags = ["default"];
    #  imports = [./devices/default.nix];
    #};
    

    headless.configuration = {
      system.nixos.tags = ["headless"];
      imports = [./devices/headless.nix];
    };
  };

  services.xserver.enable = true;

  environment.sessionVariables = {
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
  };

  security.polkit.enable = true;

  system.stateVersion = "25.05";
}
