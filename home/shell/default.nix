# Unified shell configuration for all platforms
# This is the single source of truth for zsh setup
{ config, lib, pkgs, ... }:

let
  # Platform detection
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  sshKey = "~/.ssh/id_ecdsa";
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    oh-my-zsh = {
      enable = true;
      theme = "";
      plugins = [
        "git"
        "sudo"
        "vi-mode"
        "cp"
        "history"
        "colorize"
      ] ++ lib.optionals isLinux [
        "systemadmin"
        "podman"
      ] ++ [
        "kubectl"
        "terraform"
        "rust"
        "aws"
      ];
    };

    shellAliases = {
      # Modern CLI replacements
      l = "eza --icons";
      la = "eza --icons -a";
      ll = "eza --icons -lah";
      ls = "eza --icons --color=auto";
      vim = "hx";
      cat = "bat --style plain --pager never";

      # Kubernetes
      k = "kubectl";

      # Platform-specific
    } // lib.optionalAttrs isLinux {
      docker = "podman";
    };

    initContent = ''
      # Locale
      export LANG=en_US.UTF-8
      export LC_ALL=en_US.UTF-8

      # History settings
      setopt HIST_FCNTL_LOCK
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_SPACE
      setopt SHARE_HISTORY
      HIST_STAMPS="mm/dd/yyyy"

      # Powerlevel10k theme
      source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
      [[ -f ~/.powerlevel10k ]] && source ~/.powerlevel10k

      # SSH agent setup
      ssh_session() {
        if [ -z "$SSH_AUTH_SOCK" ]; then
          eval "$(ssh-agent -s)"
        fi
        if ! ssh-add -l &>/dev/null; then
          ssh-add ${sshKey} 2>/dev/null
        fi
      }

      # SSH with agent and forwarding
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

      # Keybindings
      bindkey "^[[3~" delete-char
      bindkey "^[[5~" beginning-of-buffer-or-history
      bindkey "^[[6~" end-of-buffer-or-history
      bindkey -M emacs '^[[3;5~' kill-word
      bindkey '^H' backward-kill-word
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word
      bindkey "^[[1;3C" forward-word
      bindkey "^[[1;3D" backward-word
      bindkey "^[[1~" beginning-of-line
      bindkey "^[[4~" end-of-line

      # Architecture flags
      export ARCHFLAGS="-arch $(uname -m)"

      # SDKMAN (if installed)
      export SDKMAN_DIR="$HOME/.sdkman"
      [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
    '' + lib.optionalString isDarwin ''
      # macOS-specific helpers
      finder() { open -a "Finder" "''${1:-.}"; }
    '' + lib.optionalString isLinux ''
      # Linux-specific: keychain for SSH
      if command -v keychain &>/dev/null; then
        eval "$(keychain --eval --quiet --quick --noask --timeout 240 ${sshKey} 2>/dev/null)"
      fi
    '';
  };

  programs.keychain = lib.mkIf isLinux {
    enable = true;
  };
}
