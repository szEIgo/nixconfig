# Declarative KDE Plasma 6 configuration using plasma-manager
# Captured from actual mothership settings
{ config, lib, pkgs, plasmaEnabled ? false, ... }:

lib.mkIf plasmaEnabled {
  programs.plasma = {
    enable = true;
    overrideConfig = false;

    #
    # Workspace appearance
    #
    workspace = {
      theme = "breeze-dark";
      colorScheme = "BreezeDark";
      cursor.theme = "breeze_cursors";
      lookAndFeel = "org.kde.breezedark.desktop";
      # Solid black wallpaper
      wallpaperPlainColor = "0,0,0";
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
          # Show desktop button
          "org.kde.plasma.showdesktop"
        ];
      }
    ];

    #
    # KWin window manager settings
    #
    kwin = {
      # Single desktop (your actual config)
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
    # Window rules
    #
    window-rules = [
      {
        description = "Window settings for copyq";
        match = {
          window-class = {
            value = "CopyQ";
            type = "substring";
          };
          window-types = [ "normal" ];
        };
        apply = {
          noborder = {
            value = true;
            apply = "force";
          };
        };
      }
      {
        description = "Konsole — no titlebar and frame";
        match = {
          window-class = {
            value = "konsole";
            type = "exact";
          };
          window-types = [ "normal" ];
        };
        apply = {
          noborder = {
            value = true;
            apply = "force";
          };
        };
      }
    ];

    #
    # Global keyboard shortcuts
    #
    shortcuts = {
      # KWin window management
      kwin = {
        # Desktop switching (Meta+N and Ctrl+FN)
        "Switch to Desktop 1" = ["Meta+1" "Ctrl+F1"];
        "Switch to Desktop 2" = ["Meta+2" "Ctrl+F2"];
        "Switch to Desktop 3" = ["Meta+3" "Ctrl+F3"];
        "Switch to Desktop 4" = ["Meta+4" "Ctrl+F4"];

        # Move window to desktop (Ctrl+Alt+N)
        "Window to Desktop 1" = "Ctrl+Alt+1";
        "Window to Desktop 2" = "Ctrl+Alt+2";
        "Window to Desktop 3" = "Ctrl+Alt+3";
        "Window to Desktop 4" = "Ctrl+Alt+4";
        "Window to Desktop 5" = "Ctrl+Alt+5";

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

        # Window tiling (Quick Tile) — includes numpad shortcuts
        "Window Quick Tile Left" = ["Meta+Left" "Ctrl+Alt+Num+4"];
        "Window Quick Tile Right" = ["Meta+Right" "Ctrl+Alt+Num+6"];
        "Window Quick Tile Top" = ["Meta+Up" "Ctrl+Alt+Num+8"];
        "Window Quick Tile Bottom" = ["Meta+Down" "Ctrl+Alt+Num+2"];
        "Window Quick Tile Top Left" = "Ctrl+Alt+Num+7";
        "Window Quick Tile Top Right" = "Ctrl+Alt+Num+9";
        "Window Quick Tile Bottom Left" = "Ctrl+Alt+Num+1";
        "Window Quick Tile Bottom Right" = "Ctrl+Alt+Num+3";

        # Window actions
        "Window Close" = "Alt+F4";
        "Window Maximize" = ["Meta+PgUp" "Ctrl+Alt+Num+5" "Ctrl+Alt+PgUp" "Alt+F12"];
        "Window Minimize" = ["Meta+PgDown" "Ctrl+Alt+PgDown"];
        "Window Resize" = ["Alt+R" "Meta+R"];
        "Window Operations Menu" = "Alt+F3";

        # Move window between screens
        "Window to Next Screen" = "Meta+Shift+Right";
        "Window to Previous Screen" = "Meta+Shift+Left";

        # Overview and expose
        "Overview" = ["Meta+W" "Meta+½"];
        "Grid View" = "Meta+G";
        "Expose" = "Ctrl+F9";
        "ExposeAll" = ["Ctrl+F10" "Launch (C)"];
        "ExposeClass" = "Ctrl+F7";

        # Desktop
        "Show Desktop" = "Meta+D";
        "Edit Tiles" = "Meta+T";

        # Kill window
        "Kill Window" = ["Ctrl+Alt+Esc" "Meta+Ctrl+Esc"];

        # Walk through windows
        "Walk Through Windows" = "Alt+Tab";
        "Walk Through Windows (Reverse)" = "Alt+Shift+Tab";
        "Walk Through Windows of Current Application" = "Alt+`";
        "Walk Through Windows of Current Application (Reverse)" = "Alt+~";

        # Mouse focus
        "MoveMouseToCenter" = "Meta+F6";
        "MoveMouseToFocus" = "Meta+F5";

        # Compositing
        "Suspend Compositing" = "Alt+Shift+F12";

        # Activate demanding window
        "Activate Window Demanding Attention" = "Meta+Ctrl+A";

        # Zoom
        "view_zoom_in" = ["Meta++" "Meta+="];
        "view_zoom_out" = "Meta+-";
        "view_actual_size" = "Meta+0";
      };

      # Plasma shell shortcuts
      plasmashell = {
        "activate application launcher" = "Alt+F1";
        "manage activities" = "Meta+Q";
        "show-on-mouse-pos" = "Ctrl+Alt+C";
        "clipboard_action" = "Meta+Ctrl+X";
        "repeat_action" = "Meta+Ctrl+R";
        "show dashboard" = "Ctrl+F12";
        "cycle-panels" = "Meta+Alt+P";
        "stop current activity" = "Meta+S";
        # Disable task manager entry shortcuts (1-4 used for desktops)
        "activate task manager entry 1" = "none";
        "activate task manager entry 2" = "none";
        "activate task manager entry 3" = "none";
        "activate task manager entry 4" = "none";
        "activate task manager entry 5" = "Meta+5";
        "activate task manager entry 6" = "Meta+6";
        "activate task manager entry 7" = "Meta+7";
        "activate task manager entry 8" = "Meta+8";
        "activate task manager entry 9" = "Meta+9";
      };

      # Session management
      ksmserver = {
        "Lock Session" = ["Meta+L" "Screensaver"];
        "Log Out" = "Ctrl+Alt+Del";
      };

      # Accessibility
      kaccess = {
        "Toggle Screen Reader On and Off" = "Meta+Alt+S";
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

      # KRunner
      "org.kde.krunner.desktop" = {
        "_launch" = ["Meta" "Search" "Alt+F2"];
      };

      # Power management
      org_kde_powerdevil = {
        "Decrease Keyboard Brightness" = "Keyboard Brightness Down";
        "Decrease Screen Brightness" = "Monitor Brightness Down";
        "Decrease Screen Brightness Small" = "Shift+Monitor Brightness Down";
        "Increase Keyboard Brightness" = "Keyboard Brightness Up";
        "Increase Screen Brightness" = "Monitor Brightness Up";
        "Increase Screen Brightness Small" = "Shift+Monitor Brightness Up";
        "PowerDown" = "Power Down";
        "PowerOff" = "Power Off";
        "Sleep" = "Sleep";
        "Toggle Keyboard Backlight" = "Keyboard Light On/Off";
        "Hibernate" = "Hibernate";
        "powerProfile" = ["Battery" "Meta+B"];
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
    # Direct config file settings
    #
    configFile = {
      # KWin plugins and scripts
      kwinrc = {
        "Plugins"."krohnkiteEnabled" = true;
        "Plugins"."kzonesEnabled" = true;
        "Script-krohnkite"."screenGapBetween" = 10;
        "TabBox"."LayoutName" = "compact";
        "MouseBindings"."CommandAllKey" = "Alt";
        "Xwayland"."Scale" = 1;
      };

      # Yakuake dropdown terminal
      yakuakerc = {
        "Shortcuts"."toggle-window-state" = "F12";
        "Appearance"."Skin" = "tabsonly";
        "Appearance"."SkinInstalledWithKns" = true;
      };

      # Konsole settings
      konsolerc = {
        "Desktop Entry"."DefaultProfile" = "Profile 2.profile";
        "MainWindow"."MenuBar" = "Disabled";
        "MainWindow"."StatusBar" = "Disabled";
        "MainWindow"."ToolBarsMovable" = "Disabled";
        "Toolbar mainToolBar"."isHidden" = true;
        "Toolbar sessionToolbar"."isHidden" = true;
      };

      # Dolphin file manager
      dolphinrc = {
        "General"."ShowFullPath" = true;
        "General"."FilterBar" = true;
        "General"."ConfirmClosingTerminalRunningProgram" = false;
        "MainWindow"."MenuBar" = "Disabled";
      };

      # Global KDE settings
      kdeglobals = {
        "General"."BrowserApplication" = "firefox.desktop";
        "KDE"."SingleClick" = false;
        # LookAndFeelPackage is already set by workspace.lookAndFeel
      };

      # Disable baloo file indexer (heavy on resources)
      baloofilerc = {
        "Basic Settings"."Indexing-Enabled" = false;
      };


      # Keyboard layout
      kxkbrc = {
        "Layout"."LayoutList" = "dk";
        "Layout"."Use" = true;
      };
    };

    #
    # Input settings
    #
    input = {
      keyboard = {
        layouts = [
          { layout = "dk"; }
        ];
        repeatDelay = 250;
        repeatRate = 30;
      };
    };
  };

  # Konsole profile and color scheme
  xdg.dataFile = {
    "konsole/Profile 2.profile".text = ''
      [Appearance]
      ColorScheme=Sweet-Mars

      [General]
      Name=Profile 2
      Parent=FALLBACK/
    '';
    "konsole/Sweet-Mars.colorscheme".text = ''
      [Background]
      Color=26,30,33

      [BackgroundFaint]
      Color=40,44,52

      [BackgroundIntense]
      Color=40,44,52

      [Color0]
      Color=40,44,52

      [Color0Faint]
      Color=40,44,52

      [Color0Intense]
      Color=40,44,52

      [Color1]
      Color=246,126,125

      [Color1Faint]
      Color=246,126,125

      [Color1Intense]
      Color=246,126,125

      [Color2]
      Color=202,231,185

      [Color2Faint]
      Color=202,231,185

      [Color2Intense]
      Color=202,231,185

      [Color3]
      Color=225,221,143

      [Color3Faint]
      Color=225,221,143

      [Color3Intense]
      Color=225,221,143

      [Color4]
      Color=124,183,255

      [Color4Faint]
      Color=124,183,255

      [Color4Intense]
      Color=124,183,255

      [Color5]
      Color=215,188,200

      [Color5Faint]
      Color=215,188,200

      [Color5Intense]
      Color=215,188,200

      [Color6]
      Color=0,193,228

      [Color6Faint]
      Color=0,193,228

      [Color6Intense]
      Color=0,193,228

      [Color7]
      Color=220,223,228

      [Color7Faint]
      Color=220,223,228

      [Color7Intense]
      Color=220,223,228

      [Foreground]
      Color=195,199,209

      [ForegroundFaint]
      Color=92,99,112

      [ForegroundIntense]
      Color=130,137,151

      [General]
      Anchor=0.5,0.5
      Blur=true
      ColorRandomization=false
      Description=Sweet-Mars
      FillStyle=Tile
      Opacity=0.65
      Wallpaper=
      WallpaperFlipType=NoFlip
      WallpaperOpacity=1
    '';
    "konsole/Sweet.colorscheme".text = ''
      [Background]
      Color=22,25,37

      [BackgroundFaint]
      Color=40,44,52

      [BackgroundIntense]
      Color=40,44,52

      [Color0]
      Color=40,44,52

      [Color0Faint]
      Color=40,44,52

      [Color0Intense]
      Color=40,44,52

      [Color1]
      Color=237,37,78

      [Color1Faint]
      Color=237,37,78

      [Color1Intense]
      Color=237,37,78

      [Color2]
      Color=113,247,159

      [Color2Faint]
      Color=113,247,159

      [Color2Intense]
      Color=113,247,159

      [Color3]
      Color=249,220,92

      [Color3Faint]
      Color=249,220,92

      [Color3Intense]
      Color=249,220,92

      [Color4]
      Color=124,183,255

      [Color4Faint]
      Color=124,183,255

      [Color4Intense]
      Color=124,183,255

      [Color5]
      Color=199,77,237

      [Color5Faint]
      Color=199,77,237

      [Color5Intense]
      Color=199,77,237

      [Color6]
      Color=0,193,228

      [Color6Faint]
      Color=0,193,228

      [Color6Intense]
      Color=0,193,228

      [Color7]
      Color=220,223,228

      [Color7Faint]
      Color=220,223,228

      [Color7Intense]
      Color=220,223,228

      [Foreground]
      Color=195,199,209

      [ForegroundFaint]
      Color=92,99,112

      [ForegroundIntense]
      Color=130,137,151

      [General]
      Blur=true
      Description=Sweet
      Opacity=0.65
      Wallpaper=
    '';
    "konsole/Sweet-Ambar-Blue.colorscheme".text = ''
      [Background]
      Color=16,16,19

      [BackgroundFaint]
      Color=16,16,19

      [BackgroundIntense]
      Color=16,16,19

      [Color0]
      Color=35,38,39

      [Color0Faint]
      Color=49,54,59

      [Color0Intense]
      Color=127,140,141

      [Color1]
      Color=237,37,78

      [Color1Faint]
      Color=237,37,78

      [Color1Intense]
      Color=237,37,78

      [Color2]
      Color=113,247,159

      [Color2Faint]
      Color=113,247,159

      [Color2Intense]
      Color=113,247,159

      [Color3]
      Color=250,221,0

      [Color3Faint]
      Color=250,221,0

      [Color3Intense]
      Color=250,221,0

      [Color4]
      Color=0,114,255

      [Color4Faint]
      Color=0,114,255

      [Color4Intense]
      Color=0,114,255

      [Color5]
      Color=212,0,220

      [Color5Faint]
      Color=212,0,220

      [Color5Intense]
      Color=212,0,220

      [Color6]
      Color=0,193,228

      [Color6Faint]
      Color=0,193,228

      [Color6Intense]
      Color=0,193,228

      [Color7]
      Color=252,252,252

      [Color7Faint]
      Color=99,104,109

      [Color7Intense]
      Color=255,255,255

      [Foreground]
      Color=252,252,252

      [ForegroundFaint]
      Color=239,240,241

      [ForegroundIntense]
      Color=255,255,255

      [General]
      Anchor=0.5,0.5
      Blur=true
      ColorRandomization=false
      Description=Sweet-Ambar-Blue
      FillStyle=Tile
      Opacity=0.85
      Wallpaper=
      WallpaperOpacity=1
    '';
  };
}
