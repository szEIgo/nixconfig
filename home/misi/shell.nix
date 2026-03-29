# Misi's shell configuration
# Clean starter config — customize freely
{ config, lib, pkgs, ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    historyControl = [ "ignoredups" "ignorespace" ];
  };

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
        "history"
        "kubectl"
      ];
    };

    shellAliases = {
      l = "eza --icons";
      la = "eza --icons -a";
      ll = "eza --icons -lah";
      ls = "eza --icons --color=auto";
      vim = "hx";
      cat = "bat --style plain --pager never";
      k = "kubectl";
    };

    initContent = ''
      # Locale
      export LANG=en_US.UTF-8
      export LC_ALL=en_US.UTF-8

      # History
      setopt HIST_FCNTL_LOCK
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_SPACE
      setopt SHARE_HISTORY

      # Powerlevel10k theme
      source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

      # Keybindings
      bindkey "^[[3~" delete-char
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word
      bindkey "^[[1~" beginning-of-line
      bindkey "^[[4~" end-of-line
    '';
  };

  # Deploy p10k config (same starter theme, misi can customize later)
  home.file.".p10k.zsh".source = ../../home/configs/p10k.zsh;
}
