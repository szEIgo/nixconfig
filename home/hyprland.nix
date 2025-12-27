{ config, lib, pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    xwayland.enable = true;
    settings = { }; # leave empty if using extraConfig
    extraConfig = ''
      monitor=,preferred,auto,1

      env = XDG_CURRENT_DESKTOP,Hyprland
      env = XDG_SESSION_TYPE,wayland
      env = GDK_BACKEND,wayland
      env = QT_QPA_PLATFORM,wayland

      input {
        kb_layout = dk
      }

      # Basic bindings
      $mod = SUPER
      bind = $mod, RETURN, exec, kitty
      bind = $mod, D, exec, wofi --show drun
      bind = $mod, Q, killactive
      bind = $mod, F, fullscreen, 1
      bind = $mod, V, togglefloating
      bind = $mod, H, movefocus, l
      bind = $mod, L, movefocus, r
      bind = $mod, K, movefocus, u
      bind = $mod, J, movefocus, d

      # Workspaces
      bind = $mod, 1, workspace, 1
      bind = $mod, 2, workspace, 2
      bind = $mod, 3, workspace, 3
      bind = $mod, 4, workspace, 4
      bind = $mod, 5, workspace, 5
      bind = $mod, 6, workspace, 6
      bind = $mod, 7, workspace, 7
      bind = $mod, 8, workspace, 8
      bind = $mod, 9, workspace, 9

      # Move windows
      bind = $mod SHIFT, H, movewindow, l
      bind = $mod SHIFT, L, movewindow, r
      bind = $mod SHIFT, K, movewindow, u
      bind = $mod SHIFT, J, movewindow, d

      # Media keys
      bindl = , XF86AudioRaiseVolume, exec, pamixer -i 5
      bindl = , XF86AudioLowerVolume, exec, pamixer -d 5
      bindl = , XF86AudioMute, exec, pamixer -t
      bindl = , XF86AudioPlay, exec, playerctl play-pause
      bindl = , XF86AudioNext, exec, playerctl next
      bindl = , XF86AudioPrev, exec, playerctl previous

      # Screenshot
      bind = $mod, S, exec, grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%s).png

      # Autostart
      exec-once = waybar
      exec-once = mako
      exec-once = clipman store --no-persist &
    '';
  };

  programs.waybar.enable = true;
  programs.wofi.enable = true;

  services.mako.enable = true;
  services.clipman.enable = true;

  home.packages = with pkgs; [
    wl-clipboard
    playerctl
    pamixer
    grim
    slurp
    kitty
    wofi
    waybar
    mako
    clipman
  ];
}
