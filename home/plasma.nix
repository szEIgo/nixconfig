# Declarative KDE Plasma 6 configuration using plasma-manager
# This replaces manual config file management
{ config, lib, pkgs, plasmaEnabled ? false, ... }:

lib.mkIf plasmaEnabled {
  programs.plasma = {
    enable = true;

    #
    # Workspace appearance
    #
    workspace = {
      theme = "breeze-dark";
      colorScheme = "BreezeDark";
      cursor.theme = "breeze_cursors";
      lookAndFeel = "org.kde.breezedark.desktop";
      wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Next/contents/images/3840x2160.png";
    };

    #
    # Top panel configuration
    #
    panels = [
      {
        location = "top";
        height = 28;
        floating = true;
        widgets = [
          # Application launcher (Kickoff)
          {
            kickoff = {
              icon = "nix-snowflake-white";
            };
          }
          # Virtual desktop pager
          "org.kde.plasma.pager"
          # Task manager (icon-only)
          {
            iconTasks = {
              launchers = [ ];
              appearance = {
                showTooltips = true;
                highlightWindows = true;
                indicateAudioStreams = true;
              };
            };
          }
          # Spacer to push system tray to the right
          "org.kde.plasma.marginsseparator"
          # System tray
          {
            systemTray = {
              items = {
                shown = [
                  "org.kde.plasma.volume"
                  "org.kde.plasma.networkmanagement"
                  "org.kde.plasma.bluetooth"
                ];
                hidden = [
                  "org.kde.plasma.clipboard"
                ];
              };
            };
          }
          # Digital clock
          {
            digitalClock = {
              date = {
                enable = true;
                format = "shortDate";
                position = "belowTime";
              };
              time = {
                format = "24h";
                showSeconds = "never";
              };
            };
          }
        ];
      }
    ];

    #
    # KWin window manager settings
    #
    kwin = {
      # Virtual desktops
      virtualDesktops = {
        rows = 1;
        number = 4;
        names = [ "Desktop 1" "Desktop 2" "Desktop 3" "Desktop 4" ];
      };

      # Window behavior
      titlebarButtons = {
        left = [ "on-all-desktops" "keep-above-windows" ];
        right = [ "minimize" "maximize" "close" ];
      };

      # Effects
      effects = {
        shakeCursor.enable = true;
        desktopSwitching.animation = "slide";
      };
    };

    #
    # Global keyboard shortcuts
    #
    shortcuts = {
      # KWin window management
      kwin = {
        # Desktop switching (Meta+1-4)
        "Switch to Desktop 1" = "Meta+1";
        "Switch to Desktop 2" = "Meta+2";
        "Switch to Desktop 3" = "Meta+3";
        "Switch to Desktop 4" = "Meta+4";

        # Move window to desktop (Ctrl+Alt+1-4)
        "Window to Desktop 1" = "Ctrl+Alt+1";
        "Window to Desktop 2" = "Ctrl+Alt+2";
        "Window to Desktop 3" = "Ctrl+Alt+3";
        "Window to Desktop 4" = "Ctrl+Alt+4";

        # Desktop navigation
        "Switch One Desktop to the Left" = "Meta+Ctrl+Left";
        "Switch One Desktop to the Right" = "Meta+Ctrl+Right";
        "Switch One Desktop Up" = "Meta+Ctrl+Up";
        "Switch One Desktop Down" = "Meta+Ctrl+Down";

        # Move window between desktops
        "Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
        "Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
        "Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
        "Window One Desktop Down" = "Meta+Ctrl+Shift+Down";

        # Window switching
        "Switch Window Up" = "Meta+Alt+Up";
        "Switch Window Down" = "Meta+Alt+Down";
        "Switch Window Left" = "Meta+Alt+Left";
        "Switch Window Right" = "Meta+Alt+Right";

        # Window tiling (Quick Tile)
        "Window Quick Tile Left" = "Meta+Left";
        "Window Quick Tile Right" = "Meta+Right";
        "Window Quick Tile Top" = "Meta+Up";
        "Window Quick Tile Bottom" = "Meta+Down";

        # Window actions
        "Window Close" = "Alt+F4";
        "Window Maximize" = "Meta+PgUp";
        "Window Minimize" = "Meta+PgDown";
        "Window Resize" = ["Meta+R" "Alt+R"];

        # Move window between screens
        "Window to Next Screen" = "Meta+Shift+Right";
        "Window to Previous Screen" = "Meta+Shift+Left";

        # Overview and expose
        "Overview" = "Meta+W";
        "Grid View" = "Meta+G";
        "Expose" = "Ctrl+F9";
        "ExposeAll" = "Ctrl+F10";

        # Desktop
        "Show Desktop" = "Meta+D";
        "Edit Tiles" = "Meta+T";

        # Kill window
        "Kill Window" = ["Ctrl+Alt+Esc" "Meta+Ctrl+Esc"];

        # Zoom
        "view_zoom_in" = ["Meta++" "Meta+="];
        "view_zoom_out" = "Meta+-";
        "view_actual_size" = "Meta+0";
      };

      # Plasma shell shortcuts
      plasmashell = {
        "activate application launcher" = "Alt+F1";
        "manage activities" = "Meta+Q";
        "show-on-mouse-pos" = ["Ctrl+Alt+C" "Meta+V"];
        "clipboard_action" = "Meta+Ctrl+X";
        "repeat_action" = "Meta+Ctrl+R";
        "show dashboard" = "Ctrl+F12";
        "cycle-panels" = "Meta+Alt+P";
        "stop current activity" = "Meta+S";
      };

      # Session management
      ksmserver = {
        "Lock Session" = "Meta+L";
        "Log Out" = "Ctrl+Alt+Del";
      };

      # Keyboard layout switching
      "KDE Keyboard Layout Switcher" = {
        "Switch to Next Keyboard Layout" = "Meta+Alt+K";
        "Switch to Last-Used Keyboard Layout" = "Meta+Alt+L";
      };

      # Media controls
      mediacontrol = {
        "nextmedia" = "Media Next";
        "previousmedia" = "Media Previous";
        "playpausemedia" = "Media Play";
        "pausemedia" = "Media Pause";
        "stopmedia" = "Media Stop";
      };
    };

    #
    # Application shortcuts (hotkeys)
    #
    hotkeys.commands = {
      "launch-konsole" = {
        name = "Launch Konsole";
        key = "Ctrl+Alt+T";
        command = "konsole";
      };
      "launch-konsole-meta" = {
        name = "Launch Konsole (Meta)";
        key = "Meta+Ctrl+T";
        command = "konsole";
      };
    };

    #
    # Spectacle (screenshots) - disable recording shortcuts
    #
    spectacle.shortcuts = {
      captureRectangularRegion = "Meta+Shift+Print";
      captureActiveWindow = "Meta+Print";
      captureCurrentMonitor = "Print";
      captureEntireDesktop = "Shift+Print";
      recordRegion = "none";
      recordScreen = "none";
      recordWindow = "none";
    };

    #
    # Direct config file settings (for things not in plasma-manager)
    #
    configFile = {
      # Yakuake dropdown terminal
      yakuakerc = {
        "Shortcuts"."toggle-window-state" = "F12";
      };

      # KRunner settings
      krunnerrc = {
        "General"."FreeFloating" = true;
      };

      # Konsole settings
      konsolerc = {
        "Desktop Entry"."DefaultProfile" = "Default.profile";
      };

      # Dolphin file manager
      dolphinrc = {
        "General"."ShowFullPath" = true;
        "General"."FilterBar" = true;
      };

      # Global KDE settings
      kdeglobals = {
        "General"."BrowserApplication" = "firefox.desktop";
        "KDE"."SingleClick" = false;
      };

      # Disable baloo file indexer (heavy on resources)
      baloofilerc = {
        "Basic Settings"."Indexing-Enabled" = false;
      };
    };

    #
    # Input settings
    #
    input = {
      keyboard = {
        repeatDelay = 250;
        repeatRate = 30;
      };
    };
  };
}
