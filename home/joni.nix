{ config, lib, pkgs, plasmaEnabled ? false, isLinux ? true, isDarwin ? false
, isAndroid ? false, isPostmarketOS ? false, isServer ? false, ... }:

let
  isDesktop = isLinux && !isAndroid && !isPostmarketOS && !isServer;
  cluster = import ../modules/cluster-config.nix;

  # Fetch kubeconfig from mothership and rewrite server URL to the cluster VIP.
  # Run once after WireGuard/LAN connection is up. Re-run if certs rotate.
  fetchKubeconfig = pkgs.writeShellScriptBin "fetch-kubeconfig" ''
    set -euo pipefail
    mkdir -p "$HOME/.kube"
    echo "Fetching kubeconfig from mothership..."
    ssh mothership "sudo cat /etc/rancher/k3s/k3s.yaml" | \
      sed "s|https://127.0.0.1:6443|${cluster.apiEndpoint}|g" > "$HOME/.kube/config"
    chmod 600 "$HOME/.kube/config"
    echo "kubeconfig written to ~/.kube/config (server: ${cluster.apiEndpoint})"
  '';

  # One-time WireGuard config generator for macOS (interactive — asks for key + IP)
  wgInit = pkgs.writeShellScriptBin "wg-init" ''
    set -euo pipefail
    CONF="/etc/wireguard/wg0.conf"

    if [ -f "$CONF" ]; then
      echo "WireGuard config already exists at $CONF"
      echo "Remove it first to regenerate: sudo rm $CONF"
      exit 1
    fi

    echo "=== WireGuard config generator ==="
    echo ""
    read -rp "Your WireGuard private key: " PRIVKEY
    read -rp "Your WireGuard IP (e.g. 192.168.10.3): " WGIP

    sudo mkdir -p /etc/wireguard
    sudo tee "$CONF" > /dev/null << WGEOF
[Interface]
PrivateKey = $PRIVKEY
Address = $WGIP/24
DNS = ${cluster.wg.dns}

[Peer]
PublicKey = ${cluster.wg.serverPublicKey}
Endpoint = ${cluster.wg.endpoint}
AllowedIPs = 192.168.2.0/24, ${cluster.wg.subnet}
PersistentKeepalive = 25
WGEOF
    sudo chmod 600 "$CONF"
    echo ""
    echo "Config written to $CONF"
    echo "Connect with: wg-up (or: sudo wg-quick up wg0)"
  '';
in
{
  imports = [
    ./shell
    ./zellij
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
    ++ [ fetchKubeconfig ]
    ++ lib.optionals isDarwin [ wgInit ]
    ++ lib.optionals (!isAndroid) (import ./fonts.nix { pkgs = pkgs; })
    ++ lib.optionals isDesktop [
      # Desktop apps
      firefox
      copyq
      vscode

      # Hardware & system info
      pciutils        # lspci
      usbutils        # lsusb
      lshw            # detailed hardware info
      dmidecode       # BIOS/firmware info

      # Disk & partition management
      kdePackages.partitionmanager
      gparted
      smartmontools   # smartctl

      # Clipboard
      wl-clipboard

      # Networking & monitoring
      wireguard-tools
      atop
      netdata

      # DevOps
      kubernetes-helm
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
    settings = {
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
      "gitlab.com" = {
        HostName = "gitlab.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
      "git.govcloud.dk" = {
        HostName = "git.govcloud.dk";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
      "Match host mothership exec \"ping -c1 -W1 192.168.10.1 &>/dev/null\"" = lib.hm.dag.entryBefore [ "mothership" ] {
        HostName = "192.168.10.1";
        User = "joni";
      };
      "mothership" = {
        HostName = "192.168.2.62";
        User = "joni";
      };
      "Match host t480 exec \"ping -c1 -W1 192.168.10.5 &>/dev/null\"" = lib.hm.dag.entryBefore [ "t480" ] {
        HostName = "192.168.10.5";
        User = "joni";
      };
      "t480" = {
        HostName = "192.168.2.87";
        User = "joni";
      };
      "carrier-tc1" = {
        HostName = "192.168.2.192";
        User = "root";
      };
      "carrier-tc2" = {
        HostName = "192.168.2.250";
        User = "root";
      };
      "interceptor-nuc1" = {
        HostName = "192.168.2.102";
        User = "root";
      };
      "interceptor-tc1" = {
        HostName = "192.168.2.238";
        User = "root";
      };
      "interceptor-tc2" = {
        HostName = "192.168.2.147";
        User = "root";
      };
      "oneplus6t" = {
        HostName = "192.168.2.187";
        User = "user";
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

  # On postmarketOS, declaratively set zsh as login shell
  home.activation.setLoginShell = lib.mkIf isPostmarketOS (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ZSH_PATH="$HOME/.nix-profile/bin/zsh"
      CURRENT_SHELL=$(grep "^$(whoami):" /etc/passwd | cut -d: -f7)
      if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
        /usr/bin/grep -qxF "$ZSH_PATH" /etc/shells 2>/dev/null || /usr/bin/doas sh -c "echo $ZSH_PATH >> /etc/shells"
        /usr/bin/doas chsh -s "$ZSH_PATH" $(whoami)
      fi
    ''
  );

  home.username = lib.mkForce (
    if isAndroid then "nix-on-droid"
    else if isPostmarketOS then "user"
    else "joni"
  );
  home.homeDirectory = lib.mkForce (
    if isAndroid then "/data/data/com.termux.nix/files/home"
    else if isDarwin then "/Users/joni"
    else if isPostmarketOS then "/home/user"
    else "/home/joni"
  );
  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "25.11";
}
