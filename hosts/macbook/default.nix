{ config, lib, pkgs, ... }:

let
  # Workbrew compliance: nix-darwin's activation runs `sudo --user=joni brew bundle`
  # but workbrew refuses to run under sudo (it checks the process tree).
  #
  # Strategy: during activation, a stub "brew" intercepts the call, captures the
  # nix-generated Brewfile path, and symlinks it to ~/.Brewfile.nix.
  # The user then runs `darwin-brew` (no sudo) to apply changes via workbrew.
  brewStub = pkgs.writeShellScriptBin "brew" ''
    for arg in "$@"; do
      case "$arg" in
        --file=*)
          BREWFILE="''${arg#--file=}"
          if [ -f "$BREWFILE" ]; then
            ln -sf "$BREWFILE" "$HOME/.Brewfile.nix"
            echo "Brewfile updated: ~/.Brewfile.nix" >&2
            echo "Run 'darwin-brew' to apply changes via workbrew" >&2
          fi
          ;;
      esac
    done
  '';
in {

  system.primaryUser = "joni";

  # Nix settings (managed by Determinate, so disable nix-darwin's nix management)
  nix.enable = false;
  nixpkgs.config.allowUnfree = true;

  # Enable zsh system-wide
  # Workbrew adds group-writable directories to fpath that trigger compinit
  # security warnings. Disable system-level completion here — home-manager
  # handles it with compinit -u which silences the warnings.
  programs.zsh = {
    enable = true;
    enableCompletion = false;
  };

  # macOS system defaults
  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
      mru-spaces = false;
    };
    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "clmv";
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
    };
  };

  # Homebrew — nix-darwin generates the Brewfile declaratively, but the stub
  # captures it instead of running brew (workbrew can't run under sudo).
  # Apply with: darwin-brew
  homebrew = {
    enable = true;
    prefix = "${brewStub}";
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
    casks = [
      "alt-tab"
      "brave-browser"
      "bruno"
      "discord"
      "firefox"
      "flutter"
      "gnucash"
      "google-chrome"
      "hammerspoon"
      "iterm2"
      "krita"
      "maccy"
      "ngrok"
      "notunes"
      "postman"
      "raycast"
      "rectangle"
      "retroarch"
      "signal"
      "slack"
      "spotify"
      "teamviewer"
      "thunderbird"
      "utm"
      "vlc"
      "wakatime"
      "whatsapp"
      "whisky"
      "xquartz"
    ];
    brews = [
      # Formulae that don't have good nixpkgs equivalents on darwin
      "cocoapods"
      "docker-buildx"
      "docker-compose"
      "gitlab-runner"
      "k3d"
      "pipx"
      "rbenv"
      "ruby-build"
    ];
  };

  # macOS-specific environment packages
  environment.systemPackages = with pkgs; [
    keychain
    wireguard-tools
    wireguard-go
  ];

  security.pam.services.sudo_local.touchIdAuth = true;

  system.stateVersion = 5;
}
