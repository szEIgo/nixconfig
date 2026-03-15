# nix-darwin configuration for macOS
# To use: add nix-darwin input to flake.nix and create darwinConfigurations
#
# Example flake.nix addition:
#   inputs.nix-darwin.url = "github:LnL7/nix-darwin";
#   inputs.nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
#
#   darwinConfigurations.macbook = nix-darwin.lib.darwinSystem {
#     system = "aarch64-darwin";
#     modules = [ ./darwin ];
#   };
#
{ config, lib, pkgs, ... }:

{
  # Nix settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # System defaults
  system.defaults = {
    dock = {
      autohide = true;
      mru-spaces = false;
      minimize-to-application = true;
    };

    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      _FXShowPosixPathInTitle = true;
    };

    NSGlobalDomain = {
      AppleKeyboardUIMode = 3;
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };

    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };
  };

  # Homebrew (managed by nix-darwin)
  # homebrew = {
  #   enable = true;
  #   onActivation.cleanup = "zap";
  #   brews = [ ];
  #   casks = [ ];
  # };

  # Enable zsh
  programs.zsh.enable = true;

  # System packages (macOS-specific)
  environment.systemPackages = with pkgs; [
    coreutils
    gnused
    gnutar
  ];
}
