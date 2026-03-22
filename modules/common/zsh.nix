# NixOS system-level zsh configuration
# Configures zsh for ALL users (including root) system-wide.
# User-level config (home-manager) in home/shell/default.nix builds on top of this.
{ config, lib, pkgs, ... }:

{
  # Enable zsh system-wide as a login shell
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # Oh-my-zsh system-wide
    ohMyZsh = {
      enable = true;
      theme = "";
      plugins = [
        "git"
        "sudo"
        "vi-mode"
        "cp"
        "history"
        "colorize"
        "systemadmin"
        "kubectl"
        "terraform"
        "rust"
        "aws"
      ];
    };

    # Aliases for all users
    shellAliases = {
      l = "eza --icons";
      la = "eza --icons -a";
      ll = "eza --icons -lah";
      ls = "eza --icons --color=auto";
      vim = "hx";
      cat = "bat --style plain --pager never";
      k = "kubectl";
      docker = "podman";

      # SSH into hosts
      mothership = "ssh -X joni@192.168.2.62";
      t480 = "ssh -X joni@192.168.2.87";
      nuc = "ssh -X joni@192.168.2.102";
    };

    # Init for all users (loaded via /etc/zshrc)
    interactiveShellInit = ''
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
    '';
  };

  # Ensure CLI tools used by aliases are available system-wide
  environment.systemPackages = with pkgs; [
    eza
    bat
    helix
    zsh-powerlevel10k
  ];

  # Provide p10k config for root
  system.activationScripts.rootP10k = lib.stringAfter [ "users" ] ''
    cp ${../../home/configs/p10k.zsh} /root/.p10k.zsh
    chmod 644 /root/.p10k.zsh
  '';
}
