{ config, lib, pkgs, ... }:
{
  # GTK, icons, cursor
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

  # Kitty terminal aesthetics
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    themeFile = "One Half Dark";
    settings = {
      enable_audio_bell = false;
      background_opacity = "0.95";
      cursor_shape = "beam";
    };
  };

  # Waybar styling
  programs.waybar = {
    enable = true;
    settings = [{
      layer = "top";
      position = "top";
      height = 28;
      modules-left = [ "workspaces" "window" ];
      modules-center = [ ];
      modules-right = [ "tray" "cpu" "memory" "pulseaudio" "clock" ];
      "clock" = { format = "{:%a %d %b %H:%M}"; tooltip = true; };
      "pulseaudio" = { format = " {volume}%"; tooltip = false; on-click = "pamixer -t"; };
      "cpu" = { format = " {usage}%"; tooltip = true; };
      "memory" = { format = " {used}/{total}"; tooltip = true; };
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

  # Wofi launcher styling
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

  # Mako notifications styling
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
}
