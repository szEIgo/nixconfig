{ config, lib, pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    xwayland.enable = true;
    systemd = {
      enable = true;
      variables = [
        "DISPLAY"
        "WAYLAND_DISPLAY"
        "XDG_CURRENT_DESKTOP"
        "XDG_SESSION_TYPE"
        "XDG_RUNTIME_DIR"
      ];
    };
    settings = { };
    extraConfig = ''
      monitor=,preferred,auto,1
      $mod = SUPER
      general {
        gaps_in = 8
        gaps_out = 12
        border_size = 2
        col.active_border = rgb(89b4fa)
        col.inactive_border = rgb(313244)
      }

      decoration {
        rounding = 8
        blur {
          enabled = true
          size = 6
          passes = 2
        }
        shadow {
          enabled = true
          range = 12
          color = rgba(0,0,0,0.5)
        }
      }

      animations {
        enabled = yes
        animation = windows, 1, 7, default
        animation = windowsOut, 1, 7, default
        animation = border, 1, 10, default
        animation = fade, 1, 7, default
        animation = workspaces, 1, 6, default
      }

      # Mouse: Super+Left drag to move; Super+Right drag to resize
      bindm = $mod, mouse:272, movewindow
      bindm = $mod, mouse:273, resizewindow

      env = XDG_CURRENT_DESKTOP,Hyprland
      env = XDG_SESSION_TYPE,wayland
      env = GDK_BACKEND,wayland
      env = QT_QPA_PLATFORM,wayland

      input {
        kb_layout = dk
      }

      # Basic bindings
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
      # Wallpaper (set a real image path and enable hyprpaper below)
      # exec-once = hyprpaper

      # virtual-desktops plugin removed
    '';
  };

  programs.waybar.enable = true;
  programs.wofi.enable = true;

  services.hyprpaper = {
    enable = true;
    settings = {
      # Replace with a real image path under your home
      # preload = ["/home/joni/Pictures/wallpaper.jpg"];
      #wallpaper = ",/home/joni/Pictures/wallpaper.jpg";
    };
  };

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
