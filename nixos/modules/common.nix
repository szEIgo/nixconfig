# ./nixos/modules/common.nix
# Shared settings for all mothership configurations
{ pkgs, ... }: {
  # Locales
  time.timeZone = "Europe/Copenhagen";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    keyMap = "dk";
    useXkbConfig = true;
  };

  # Users
  users.users.joni = {
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" "podman" ]; # Essential groups
    shell = pkgs.zsh;
  };
  users.defaultUserShell = pkgs.zsh;

  # Networking
  networking.useDHCP = false; # Using systemd-networkd for static IP
  networking.networkmanager.enable = true; # For desktop environments
  systemd.network.enable = true;
  services.resolved.enable = true;

  systemd.network.networks."enp6s0" = {
    matchConfig.Name = "enp6s0";
    address = [ "192.168.2.62/24" ];
    gateway = "192.168.2.1";
    dns = [ "192.168.2.1" ];
  };

  # General packages and settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  programs.zsh.enable = true;
  security.polkit.enable = true;
  zramSwap.enable = true;

  # Common system packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    pciutils
    usbutils
    wireguard-tools
    git
  ];

  # Set XDG base directories system-wide
  environment.sessionVariables = {
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
  };

  # System state version
  system.stateVersion = "25.05";
}
