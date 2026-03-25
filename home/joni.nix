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
    # Heavier tools (skip on Android — slow to build, large closure)
    # Language runtimes & SDKs are in per-project devShells via direnv
    ++ lib.optionals (!isAndroid) [
      # DevOps / K8s
      kubectl
      kustomize
      fluxcd
      k9s
      cosign

      # Networking & monitoring
      nmap
      speedtest-cli
      sshpass
      zellij
    ]
    ++ lib.optionals (!isAndroid) (import ./fonts.nix { pkgs = pkgs; })
    ++ lib.optionals isDesktop [
      # Linux desktop-only packages
      wl-clipboard
      kubernetes-helm
      firefox
      copyq
      vscode
      wireguard-tools
      atop
      netdata
    ];

  # Direnv + nix-direnv for per-project dev environments
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  programs.ssh = lib.mkIf (!isAndroid) {
    enable = true;
    enableDefaultConfig = false;
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
      "mothership-wg" = {
        match = ''host mothership exec "ping -c1 -W1 192.168.10.1 &>/dev/null"'';
        hostname = "192.168.10.1";
        user = "joni";
      };
      "mothership-lan" = {
        host = "mothership";
        hostname = "192.168.2.62";
        user = "joni";
      };
      "t480-wg" = {
        match = ''host t480 exec "ping -c1 -W1 192.168.10.5 &>/dev/null"'';
        hostname = "192.168.10.5";
        user = "joni";
      };
      "t480-lan" = {
        host = "t480";
        hostname = "192.168.2.87";
        user = "joni";
      };
      "nuc" = {
        hostname = "192.168.2.102";
        user = "joni";
      };
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Jonathan Szigethy";
        email = "jonathan@szigethy.dk";
      };
      core = {
        editor = "vim";
        autocrlf = "input";
        excludesfile = "~/.gitignore_global";
      };
      color.ui = true;
      push.default = "simple";
    };
  };

  home.file.".gitignore_global".text = ".direnv/\n";
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
