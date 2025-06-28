{ config, pkgs, lib, ... }:

let sshKey = "~/.ssh/id_ecdsa";
in {
  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "";
      plugins = [ "git" "sudo" "terraform" "systemadmin" "vi-mode" ];
    };

    shellAliases = {
      l = "eza --icons";
      la = "eza --icons -a";
      ll = "eza --icons -lah";
      ls = "eza --icons --color=auto";
      docker = "podman";
      vim = "hx";
      sw_debian = "ssh -J bastion@51.158.121.209:61000 root@172.16.16.5";
      sw_ubuntu = "ssh -J bastion@51.15.132.29:61000 root@172.16.4.2";
    };

    enableCompletion = true;

    initContent = ''
      # Locale
      export LANG=en_US.UTF-8
      export LC_ALL=en_US.UTF-8

      setopt HIST_FCNTL_LOCK
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_SPACE
      setopt SHARE_HISTORY
      HIST_STAMPS="mm/dd/yyyy"

      # Powerlevel10k theme
      source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

      # SSH agent setup
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
        command scp -C -v -r -o StrictHostKeyChecking=no "$@"
      }

      git() {
        ssh_session
        command git "$@"
      }

      # SDKMAN
      export SDKMAN_DIR="$HOME/.sdkman"
      [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

      # SSH Keychain
      eval "$(keychain --eval --quiet --quick --noask --timeout 240 ${sshKey})"

      # Aliases
      finder() { open -a "Finder" "${"1:-."}"; }
      dolphin() { finder "$@"; }

      # Custom cat override
      cat() { bat --style plain --pager never "$@"; }

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

      # Zoxide
      # source "${pkgs.zoxide}/share/zoxide/init.zsh"
    '';
  };

  programs.keychain.enable = true;

}
