{ config, lib, pkgs, plasmaEnabled ? false, isLinux ? true, isDarwin ? false
, isAndroid ? false, ... }:

let
  isDesktop = isLinux && !isAndroid;
in
{
  imports = [
    ./shell
  ] ++ lib.optionals (!isAndroid) [
    ./theme-kitty.nix
  ] ++ lib.optionals isDesktop [
    ./hyprland.nix
  ] ++ lib.optionals plasmaEnabled [
    ./plasma.nix      # Declarative Plasma config via plasma-manager
  ];

  home.file = {
    ".powerlevel10k".source = ./configs/p10k.zsh;
  };

  # Core CLI packages shared across ALL platforms (including Android)
  home.packages = with pkgs;
    [
      # Core CLI tools
      neovim
      git
      htop
      btop
      wget
      ripgrep
      jq
      fd
      eza
      bat
      tree
      dust
      ncdu
      tmux
      watch
      tldr
      glow
      yq
      gnupg

      # Shell
      zsh
      zsh-powerlevel10k
      oh-my-zsh

      # Dev tools
      gnumake
      gh
      glab
      sops
      age
      vim
      helix

      # Networking
      fzf
      zoxide
      openssh

      # Misc
      mc
      yamllint
      yazi
    ]
    # Heavier dev tools (skip on Android — slow to build, large closure)
    ++ lib.optionals (!isAndroid) [
      # Languages & runtimes
      sbt
      scala
      rustc
      cargo
      rustfmt
      pnpm
      uv

      # DevOps / K8s
      kubectl
      kustomize
      fluxcd
      k9s
      cosign

      # Infrastructure
      opentofu
      pulumi

      # Networking & monitoring
      nmap
      speedtest-cli
      sshpass
      zellij

      # Clipboard
      wl-clipboard

      # Misc
      graphviz
      plantuml
      jdk
    ]
    ++ lib.optionals (!isAndroid) (import ./fonts.nix { pkgs = pkgs; })
    ++ lib.optionals isDesktop [
      # Linux desktop-only packages
      kubernetes-helm
      firefox
      copyq
      vscode
      wireguard-tools
      atop
      netdata
    ];

  programs.ssh = lib.mkIf (!isAndroid) {
    enable = true;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };
      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };
      "git.govcloud.dk" = {
        hostname = "git.govcloud.dk";
        user = "git";
        identityFile = "~/.ssh/id_ecdsa";
        identitiesOnly = true;
      };
      "nuc" = {
        hostname = "192.168.2.102";
        user = "joni";
      };
      "t480" = {
        hostname = "192.168.2.87";
        user = "joni";
      };
    };
  };

  programs.git = {
    enable = true;
    userName = "Jonathan Szigethy";
    userEmail = "jonathan@szigethy.dk";
    extraConfig = {
      core = {
        editor = "vim";
        autocrlf = "input";
      };
      color.ui = true;
      push.default = "simple";
    };
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.fzf.enable = true;

  programs.helix = {
    enable = true;
    settings = {
      theme = "autumn_night_transparent";
      editor.cursor-shape = {
        normal = "block";
        insert = "bar";
        select = "underline";
      };
    };
    languages.language = [{
      name = "nix";
      auto-format = true;
      formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
    }];
    themes = {
      autumn_night_transparent = {
        "inherits" = "autumn_night";
        "ui.background" = { };
      };
    };
  };

  home.username = lib.mkForce (if isAndroid then "nix-on-droid" else "joni");
  home.homeDirectory = lib.mkForce (
    if isAndroid then "/data/data/com.termux.nix/files/home"
    else if isDarwin then "/Users/joni"
    else "/home/joni"
  );
  home.stateVersion = "25.11";
}
