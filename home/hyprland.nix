{ config, lib, pkgs, ... }:
{
  # ── GTK, icons, cursor (Catppuccin Mocha) ──
  gtk = {
    enable = true;
    theme = {
      package = pkgs.catppuccin-gtk;
      name = "Catppuccin-Mocha-Standard-Blue-Dark";
    };
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
    cursorTheme = {
      package = pkgs.catppuccin-cursors;
      name = "Catppuccin-Mocha-Dark";
      size = 24;
    };
  };

  home.pointerCursor = {
    name = "Catppuccin-Mocha-Dark";
    package = pkgs.catppuccin-cursors;
    size = 24;
  };

  # ── Hyprland window manager ──
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

  # ── Waybar styling (Catppuccin) ──
  programs.waybar = {
    enable = true;
    settings = [{
      layer = "top";
      position = "top";
      height = 28;
      modules-left = [ "workspaces" "window" ];
      modules-center = [ ];
      modules-right = [ "tray" "cpu" "memory" "pulseaudio" "clock" ];
      "clock" = {
        format = "{:%a %d %b %H:%M}";
        tooltip = true;
      };
      "pulseaudio" = {
        format = " {volume}%";
        tooltip = false;
        on-click = "pamixer -t";
      };
      "cpu" = {
        format = " {usage}%";
        tooltip = true;
      };
      "memory" = {
        format = " {used}/{total}";
        tooltip = true;
      };
    }];
    style = ''
      * { font-family: JetBrainsMono Nerd Font, FontAwesome; font-size: 12px; }
      window { background-color: #11111b; color: #cdd6f4; }
      #workspaces button { padding: 0 8px; background: transparent; color: #cdd6f4; }
      #workspaces button.focused { background: #1e1e2e; border-radius: 6px; }
      #window { padding: 0 10px; }
      #tray, #cpu, #memory, #pulseaudio, #clock { padding: 0 10px; margin: 0 4px; background: #1e1e2e; border-radius: 8px; }
    '';
  };

  # ── Wofi launcher styling (Catppuccin) ──
  programs.wofi = {
    enable = true;
    settings = {
      allow_images = true;
      width = 800;
      height = 450;
      lines = 10;
      prompt = "Search";
      hide_scroll = true;
    };
    style = ''
      * { font-family: JetBrainsMono Nerd Font; }
      window { background-color: #11111b; }
      #input { margin: 8px; padding: 8px; border-radius: 8px; background: #1e1e2e; color: #cdd6f4; }
      #list { margin: 8px; }
      #entry:selected { background: #313244; }
    '';
  };

  # ── Mako notifications (Catppuccin) ──
  services.mako = {
    enable = true;
    settings = {
      background-color = "#1e1e2e";
      text-color = "#cdd6f4";
      border-color = "#89b4fa";
      border-radius = 8;
      default-timeout = 5000;
      margin = "10";
      padding = "10";
    };
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      # Replace with a real image path under your home
      # preload = ["/home/joni/Pictures/wallpaper.jpg"];
      #wallpaper = ",/home/joni/Pictures/wallpaper.jpg";
    };
  };

  # Only run clipman under Hyprland — on Plasma, KDE's built-in clipboard handles this
  services.clipman.enable = lib.mkDefault false;

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
