{ config, lib, pkgs, plasmaEnabled ? false, isLinux ? true, isDarwin ? false
, ... }: {

  imports = [
    ./shell
    ./theme-kitty.nix
  ] ++ lib.optionals isLinux [
    ./hyprland.nix
    ./plasma6.nix
  ];

  home.file = {
    "./.gitconfig".source = ./configs/gitconfig;
    ".powerlevel10k".source = ./configs/p10k.zsh;
  };

  # Cross-platform packages (shared between NixOS and macOS)
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
      fzf
      zoxide
      speedtest-cli

      # Misc
      graphviz
      plantuml
      jdk
      mc
      yamllint
      sshpass
      yazi
      zellij
    ]
    ++ import ./fonts.nix { pkgs = pkgs; }
    ++ lib.optionals isLinux [
      # Linux-only packages
      helm
      firefox
      copyq
      vscode
      wireguard-tools
      atop
      netdata
    ];

  programs.git.enable = true;
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

  home.username = "joni";
  home.homeDirectory = lib.mkForce (if isDarwin then "/Users/joni" else "/home/joni");
  home.stateVersion = "25.11";
}
