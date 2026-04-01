# Unified shell configuration for all platforms
# This is the single source of truth for shell setup
{ config, lib, pkgs, isAndroid ? false, isPostmarketOS ? false, ... }:

let
  # Platform detection
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  isDesktop = isLinux && !isAndroid && !isPostmarketOS;
in
{
  # Minimal bash configuration (used by tools like Claude Code)
  programs.bash = {
    enable = true;
    enableCompletion = true;

    historyControl = [ "ignoredups" "ignorespace" ];

    initExtra = ''
      # Locale
      export LANG=en_US.UTF-8
      export LC_ALL=en_US.UTF-8

      # Architecture flags
      export ARCHFLAGS="-arch $(uname -m)"

    '';
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # Workbrew adds group-writable directories to fpath; -u tells compinit
    # to silently use them instead of prompting about insecure directories
    completionInit = lib.optionalString isDarwin "autoload -U compinit && compinit -u";

    oh-my-zsh = {
      enable = true;
      theme = "";
      extraConfig = lib.optionalString isDarwin ''
        # Workbrew adds directories to fpath that zsh considers insecure
        ZSH_DISABLE_COMPFIX=true
      '';
      plugins = [
        "git"
        "sudo"
        "vi-mode"
        "cp"
        "history"
        "colorize"
      ] ++ lib.optionals isDesktop [
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

      # SSH into hosts
      mothership = "ssh -X -o ConnectTimeout=2 joni@192.168.10.1 || ssh -X -o ConnectTimeout=5 joni@192.168.2.62";
      t480 = "ssh -X -o ConnectTimeout=2 joni@192.168.10.5 || ssh -X -o ConnectTimeout=5 joni@192.168.2.87";

      # k3s fleet (Protoss naming: carriers = control plane, interceptors = workers)
      carrier-tc1 = "ssh -o ConnectTimeout=2 root@192.168.2.192";
      carrier-tc2 = "ssh -o ConnectTimeout=2 root@192.168.2.250";
      interceptor-nuc1 = "ssh -o ConnectTimeout=2 root@192.168.2.102";
      interceptor-tc1 = "ssh -o ConnectTimeout=2 root@192.168.2.238";
      interceptor-tc2 = "ssh -o ConnectTimeout=2 root@192.168.2.147";

      oneplus6t = "ssh -o ConnectTimeout=2 user@192.168.2.187";

      # Platform-specific
    } // lib.optionalAttrs isDesktop {
      docker = "podman";
    };

    envExtra = lib.optionalString isPostmarketOS ''
      # Source Nix profile on non-NixOS (postmarketOS)
      if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/nix.sh"
      fi
    '';

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

      # GPG agent: update TTY/display so pinentry works in current session
      export GPG_TTY=$(tty)
      gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true

      # SDKMAN (if installed)
      export SDKMAN_DIR="$HOME/.sdkman"
      [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
    '' + lib.optionalString isDarwin ''
      # macOS-specific helpers
      finder() { open -a "Finder" "''${1:-.}"; }
    '';
  };

  # Deploy p10k config so powerlevel10k theme works on all machines
  home.file.".p10k.zsh".source = ../configs/p10k.zsh;
}
