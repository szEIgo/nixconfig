{ config, lib, pkgs, ... }: {

  # Provide p10k config for root so it gets the same styled prompt
  system.activationScripts.rootP10k = lib.stringAfter [ "users" ] ''
    cp ${../../home/configs/p10k.zsh} /root/.p10k.zsh
    chmod 644 /root/.p10k.zsh
  '';

  programs.zsh = {
    enable = true;

    shellAliases = {
      l = "eza --icons";
      la = "eza --icons -a";
      ll = "eza --icons -lah";
      ls = "eza --icons --color=auto";
      docker = "podman";
      vim = "hx";
    };

    interactiveShellInit = ''
      # Locale
      export LANG=en_US.UTF-8
      export LC_ALL=en_US.UTF-8

      # History
      setopt HIST_FCNTL_LOCK
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_SPACE
      setopt SHARE_HISTORY
      HIST_STAMPS="mm/dd/yyyy"

      # Powerlevel10k theme
      source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

      # Custom cat override
      cat() { ${pkgs.bat}/bin/bat --style plain --pager never "$@"; }

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
    '';
  };
}
