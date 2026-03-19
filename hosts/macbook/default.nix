{ config, lib, pkgs, ... }: {

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Enable zsh system-wide
  programs.zsh.enable = true;

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
