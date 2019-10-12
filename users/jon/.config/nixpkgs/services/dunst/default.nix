{ pkgs, ... }:
with pkgs;
{
  services.dunst = {
    enable = true;

    iconTheme.package = pkgs.gnome3.adwaita-icon-theme;
    iconTheme.name = "Adwaita";

    settings = {

      frame = {
        width = "2";
        color = "#1d2021";
      };

      urgency_low = {
        background = "#282828";
        foreground = "#ebdbb2";
        timeout    = "5";
      };

      urgency_normal = {
        background = "#3c3836";
        foreground = "#ffffff";
        timeout    = "10";
      };

      urgency_critical = {
        background = "#fabd2f";
        foreground = "#000000";
        timeout    = "0";
      };

      global = {
        # The format of the message.  Possible variables:
        #   %a  appname
        #   %s  summary
        #   %b  body
        #   %i  iconname (including its path)
        #   %I  iconname (without its path)
        #   %p  progress value if set ([  0%] to [100%]) or nothing
        format = ''%a\n<b>%s</b>\n%b\n%p'';

        # The geometry of the window. Format: [{width}]x{height}[+/-{x}+/-{y}]
        # The height = number of notifications, all other variables are px
        # Omit width, provide height for full-screen width notifications
        # If width is 0, window will fit to longest message
        # Positive x value is measured from the left of the screen, negative x is measured from the right
        # Positive y value is measured from the top of the screen
        geometry            = "400x5-30+55";

        font                = "Roboto 10";
        allow_markup        = "yes";
        plain_text          = "no";          # Treat message as plain text
        sort                = "yes";         # Sort messages by urgency
        indicate_hidden     = "yes";         # Show how many messages are currently hidden (see geometry)
        alignment           = "center";      # Align text left/center/right
        bounce_freq         = "0";           # Frequency to bounce text back and forth if it is longer than the window width (conflicts with "word_wrap")
        show_age_threshold  = "60";          # Show if message is older than x seconds (-1 to disable)
        word_wrap           = "yes";         # Split notifications into multiple lines if they don't fit into geometry
        ignore_newline      = "no";          # Ignore "\n"
        transparency        = "10";          # The transparency of the window. 0 (opaque) to 100 (transparent) - requires compositing window manager (xcompmgr, compiz, compton, etc)
        shrink              = "no";          # Shrink window if it's smaller than the width (ignored if width is 0)
        monitor             = "0";           # Display notifications on the monitor indicated (0 is default)
        follow              = "none";        # Follow mouse/keyboard/none
        show_indicators     = "no";          # Display indicators for URLs (U) and actions (A)
        line_height         = "0";           # The spacing between lines (forced to height of font at minimum)
        notification_height = "0";           # The height of the entire notification (forced to height of font height and padding at minimum)
        separator_height    = "2";           # Space in pixels between two notifications
        padding             = "8";           # Padding between text and separator
        horizontal_padding  = "8";           # Horizontal padding
        separator_color     = "frame";       # Color for separator: auto/foreground/frame/X color
        icon_position       = "left";        # Align icons left/right/off
        max_icon_size       = "64";

        idle_threshold      = "120";         # Don't remove messages if the user is idle (no mouse or keyboard input) for longer than idle_threshold seconds
        sticky_history      = "yes";         # Make notifications remain until clicked on (yes) or timeout as normal (no) when recalled from history
        history_length      = "20";          # Maximum amount of notifications kept in history

        dmenu               = ''${pkgs.rofi}/bin/rofi -dmenu -p dunst:'';
        browser             = ''${pkgs.google-chrome}/bin/google-chrome-stable'';
      };

      shortcuts = {
        # Available modifiers are "ctrl", "mod1", "mod2", "mod3", and "mod4"
        # Xev might be helpful to find names for keys

        # Close notification
        close = "ctrl+space";

        # Close all notifications
        close_all = "ctrl+shift+space";

        # Recall last message(s) 
        history = "mod1+grave";

        # Context menu
        context = "ctrl+shift+period";

      };
    };
  };
}
