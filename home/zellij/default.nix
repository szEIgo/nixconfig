# Zellij terminal multiplexer configuration
# Manages sessions, layouts, keybindings, and auto-attach behavior
{ config, lib, pkgs, ... }:

{
  programs.zellij = {
    enable = true;
    # We handle auto-start ourselves to always target the "main" session
    enableZshIntegration = false;
    settings = {
      # Use our custom layout with compact-bar + status-bar (tips/shortcuts)
      default_layout = "custom";
      default_shell = "zsh";

      # Session management
      on_force_close = "detach";
      session_serialization = true;
      pane_viewport_serialization = true;
      scrollback_lines_to_serialize = 1000;

      # UI
      simplified_ui = false;
      pane_frames = true;
      auto_layout = true;
      mouse_mode = true;
      copy_on_select = true;

      # Theme — transparent background to match terminal
      theme = "custom";
      themes.custom = {
        bg = "#1e1e2e";
        fg = "#cdd6f4";
        red = "#f38ba8";
        green = "#a6e3a1";
        blue = "#89b4fa";
        yellow = "#f9e2af";
        magenta = "#cba6f7";
        orange = "#fab387";
        cyan = "#94e2d5";
        black = "#181825";
        white = "#cdd6f4";
      };
    };
  };

  # Deploy custom layout
  home.file.".config/zellij/layouts/custom.kdl".source = ./layout.kdl;

  # Auto-attach to "main" session — runs at order 200 (earliest, same slot as
  # enableZshIntegration would use) so it executes before anything else in .zshrc.
  # Every new terminal window/tab joins "main" as a new zellij tab.
  programs.zsh.initContent = lib.mkOrder 200 ''
    if [[ -z "$ZELLIJ" ]]; then
      # Clean up dead/exited sessions automatically
      zellij delete-all-sessions --yes 2>/dev/null

      # Attach to "main" session as a new tab, or create it if it doesn't exist
      zellij attach main --create

      # When detaching/exiting zellij, also exit the shell (no orphan shells)
      exit
    fi
  '';

  # Zellij shell aliases and session management helpers
  programs.zsh.shellAliases = {
    zj = "zellij";
    zja = "zellij attach";
    zjl = "zellij list-sessions";
    zjd = "zellij delete-session";
    zjk = "zellij kill-session";
    zjka = "zellij kill-all-sessions";
    zjda = "zellij delete-all-sessions";
    # Attach to a named session or create it
    zjn = "f() { zellij attach \"$1\" --create; }; f";
  };
}
