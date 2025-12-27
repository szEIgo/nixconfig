{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.gamemode.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  services.printing.enable = true;

  environment.systemPackages = with pkgs; [
    kitty
    wofi
    waybar
    mako
    wl-clipboard
    clipman
    playerctl
    pamixer
    grim
    slurp
    gamescope
    gamemode
  ];

    # Enable XDG portals for Wayland apps and Hyprland
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
    };
}
