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

  xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
    };
}
