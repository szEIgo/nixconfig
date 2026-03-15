{ config, pkgs, lib, ... }:

let sshKey = "~/.ssh/id_ecdsa";
in {

  programs.zellij = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      show_startup_tips = false;
      default_layout = "compact";
      default_shell = "zsh";
    };

  };
  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "";
      plugins = [
        "git"
        "sudo"
        "terraform"
        "systemadmin"
        "vi-mode"
        "terraform"
        "scala"
        "rust"
        "redis-cli"
        "cp"
        "history"
        "kubectl"
        "podman"
        "colorize"
        "aws"
      ];
    };

    shellAliases = {
      sw_debian = "ssh -J bastion@51.158.121.209:61000 root@172.16.16.5";
      sw_ubuntu = "ssh -J bastion@51.15.132.29:61000 root@172.16.4.2";
      k = "sudo KUBECONFIG=/etc/kubernetes/kubeconfig-admin.yaml kubectl";
    };

    enableCompletion = true;

    initContent = ''
      # SSH agent setup — user-only, never root
      ssh_session() {
        if [ -z "$SSH_AUTH_SOCK" ]; then
          eval "$(ssh-agent -s)"
        fi

        if ! ssh-add -l &>/dev/null; then
          ssh-add ${sshKey} &>/dev/null
        fi
      }

      # SSH overrides
      ssh() {
        ssh_session
        command ssh -X -CY -o ServerAliveInterval=120 "$@"
      }

      scp() {
        ssh_session
        command scp -C -v -r "$@"
      }

      git() {
        ssh_session
        command git "$@"
      }

      # SDKMAN
      export SDKMAN_DIR="$HOME/.sdkman"
      [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

      # SSH Keychain — user-only
      eval "$(keychain --eval --quiet --quick --noask --timeout 240 ${sshKey})"

      # User helpers
      finder() { open -a "Finder" "${"1:-."}"; }
      dolphin() { finder "$@"; }

      # Zoxide
      # source "${pkgs.zoxide}/share/zoxide/init.zsh"
    '';
  };

  programs.keychain.enable = true;

}
