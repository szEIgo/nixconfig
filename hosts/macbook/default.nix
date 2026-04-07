{ config, lib, pkgs, ... }:

let
  # Workbrew replaces /opt/homebrew/bin/brew with a shim that refuses to run
  # under sudo. nix-darwin's activation calls `sudo --user=joni brew bundle`,
  # so workbrew always detects sudo in the process tree and aborts.
  # Fix: strip workbrew env vars and call Homebrew's real entry point directly.
  brewWrapper = pkgs.writeShellScriptBin "brew" ''
    unset HOMEBREW_FORCE_BREW_WRAPPER
    unset HOMEBREW_BREW_WRAPPER

    # Try the real Homebrew entry point (bypasses workbrew shim)
    if [ -x /opt/homebrew/Library/Homebrew/brew.sh ]; then
      export HOMEBREW_PREFIX="/opt/homebrew"
      export HOMEBREW_REPOSITORY="/opt/homebrew"
      export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
      exec /opt/homebrew/Library/Homebrew/brew.sh "$@"
    fi

    # Fallback: call brew directly with cleaned env
    exec /opt/homebrew/bin/brew "$@"
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

  # Homebrew integration for GUI apps that aren't in nixpkgs
  homebrew = {
    enable = true;
    prefix = "${brewWrapper}";
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
