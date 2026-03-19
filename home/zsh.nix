{ config, pkgs, lib, isLinux ? true, isDarwin ? false, ... }:

let
  sshKey = "~/.ssh/id_ecdsa";
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
    enableCompletion = true;

    history = {
      size = 100000000;
      save = 100000000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
    };

    oh-my-zsh = {
      enable = true;
      theme = "";
      plugins = [
        "git"
        "sudo"
        "terraform"
        "scala"
        "rust"
        "redis-cli"
        "cp"
        "history"
        "kubectl"
        "podman"
        "colorize"
        "colored-man-pages"
        "aws"
        "argocd"
        "docker"
        "postgres"
        "zoxide"
        "vi-mode"
        "systemadmin"
      ] ++ lib.optionals isDarwin [
        "brew"
        "iterm2"
        "xcode"
      ];
    };

    shellAliases = {
      # eza (standardized — exa is unmaintained)
      l = "eza --icons";
      la = "eza --icons -a";
      ll = "eza --icons -lah";
      ls = "eza --icons --color=auto";

      # Editor
      vim = "hx";

      # Remote hosts
      sw_debian =
        "ssh -J bastion@51.158.121.209:61000 root@172.16.16.5";
      sw_ubuntu =
        "ssh -J bastion@51.15.132.29:61000 root@172.16.4.2";
      mothership = "ssh -X joni@192.168.2.62";
      nuc = "ssh -p 666 root@192.168.2.102";

      scaleway = "scw";
    } // lib.optionalAttrs isLinux {
      docker = "podman";
      k =
        "sudo KUBECONFIG=/etc/kubernetes/kubeconfig-admin.yaml kubectl";
    };

    initContent = ''
      # ── Locale ──
      export LANG=en_US.UTF-8
      export LC_ALL=en_US.UTF-8
      export ARCHFLAGS="-arch $(uname -m)"

      # ── History ──
      setopt HIST_FCNTL_LOCK
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_SPACE
      setopt SHARE_HISTORY
      HIST_STAMPS="mm/dd/yyyy"

      # ── Powerlevel10k ──
      source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

      # ── bat as cat ──
      cat() { ${pkgs.bat}/bin/bat --style plain --pager never "$@"; }

      # ── Keybindings ──
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

      # ── SSH agent ──
      ssh_session() {
        if [ -z "$SSH_AUTH_SOCK" ]; then
          eval "$(ssh-agent -s)"
        fi
        if ! ssh-add -l &>/dev/null; then
          ssh-add ${sshKey} &>/dev/null
        fi
      }

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

      # ── Keychain ──
      eval "$(keychain --eval --quiet --quick --noask --timeout 240 ${sshKey})"

      # ── File browser helpers ──
    '' + (if isDarwin then ''
      finder() {
        if [ -z "$1" ]; then
          open -a "Spacedrive" .
        else
          open -a "Spacedrive" "$1"
        fi
      }
    '' else ''
      finder() { xdg-open "''${1:-.}"; }
    '') + ''
      dolphin() { finder "$@"; }

      # ── Scaleway CLI (Docker) ──
      scw() {
    '' + (if isDarwin then ''
        docker run -i --net=host -v /Users/$USER/.config/scw:/root/.config/scw --rm scaleway/cli:latest "$@"
    '' else ''
        podman run -i --net=host -v /home/$USER/.config/scw:/root/.config/scw --rm scaleway/cli:latest "$@"
    '') + ''
      }

      # ── repeat helper ──
      repeat() {
        local interval count cmd sleep_time
        case $1 in
          (*ms|*s)
            interval=$1; shift
            [[ $1 =~ ^[0-9]+$ ]] && { count=$1; shift } || count=-1
            cmd=$@ ;;
          ([0-9]##)
            count=$1; shift; cmd=$@ ;;
          (*)
            interval=1s; count=-1; cmd=$@ ;;
        esac
        [[ $interval =~ ms$ ]] && sleep_time=$(( ''${interval%ms}/1000.0 )) || sleep_time=''${interval%s}
        if (( count == -1 )); then
          while eval $cmd; do sleep $sleep_time; done
        else
          for ((i=1; i<=$count; i++)); do
            eval $cmd
            (( i < count )) && sleep $sleep_time
          done
        fi
      }

      # ── SDKMAN ──
      export SDKMAN_DIR="$HOME/.sdkman"
      [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

      # ── Extra PATHs ──
      export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

      # ── VSCode shell integration ──
      [[ "$TERM_PROGRAM" == "vscode" ]] && [[ -x "$(command -v code)" ]] && . "$(code --locate-shell-integration-path zsh)"

      # ── Bun (macOS) ──
    '' + lib.optionalString isDarwin ''
      export BUN_INSTALL="$HOME/.bun"
      export PATH="$BUN_INSTALL/bin:$PATH"
      [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

      # IntelliJ IDEA launcher
      idea() {
        nohup "/Applications/IntelliJ IDEA.app/Contents/MacOS/idea" "$@" > /dev/null 2>&1 &
      }
    '' + ''

      # ── Completions ──
      fpath=(~/.zsh/completion $fpath)
    '';
  };

  programs.keychain.enable = true;
}
