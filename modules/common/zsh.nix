{ config, lib, pkgs, ... }:

let
  sshKey = "${config.home.homeDirectory}/.ssh/id_ecdsa";
in
{
  home.packages = with pkgs; [
    eza
    bat
    keychain
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    #autosuggestions.enable = true;
    #syntaxHighlighting.enable = true;

    shellAliases = {
      l = "eza --icons";
      la = "eza --icons -a";
      ll = "eza --icons -lah";
      ls = "eza --icons --color=auto";
    };

    envExtra = ''
      export LANG=en_US.UTF-8
      export LC_ALL=en_US.UTF-8
      export PATH="$HOME/.cargo/bin:$PATH"
      export HISTFILE="$HOME/.zsh_history"
      export HISTSIZE=10000
      export SAVEHIST=10000
      mkdir -p "$(dirname "$HISTFILE")"
      export ARCHFLAGS="-arch $(uname -m)"
    '';

    history = {
      share = true;
      expireDuplicatesFirst = false;
      ignoreDups = true;
      ignoreSpace = true;
      save = 10000;
      size = 10000;
    };

    initExtra = ''
      bindkey "^[[3~" delete-char
      bindkey "^[[5~" beginning-of-buffer-or-history
      bindkey "^[[6~" end-of-buffer-or-history
      bindkey -M emacs '^[[3;5~' kill-word
      bindkey '^H' backward-kill-word
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word
      bindkey "^[[1;3C" forward-word
      bindkey "^[[1;3D" backward-word
      bindkey '^[[1~' beginning-of-line
      bindkey '^[[4~' end-of-line

      fpath=(~/.zsh/completion $fpath)
      source ~/.zsh/functions/ssh-overrides.zsh
    '';

    #programs.zsh.autosuggestions.enable
    #programs.zsh.syntaxHighlighting.enable

    zplug = {
      enable = true;
      plugins = [
        { name = "ohmyzsh/ohmyzsh"; tags = [ "lib" ]; }
        { name = "zsh-users/zsh-autosuggestions"; }
        { name = "zsh-users/zsh-syntax-highlighting"; }
      ];
    };
  };

 # services.keychain = {
 #   enable = true;
 #   keys = [ sshKey ];
 #   agents = [ "ssh" ];
 #   extraFlags = [ "--quiet" "--quick" "--noask" "--timeout" "240" ];
 # };

  #home.file.".zsh/functions/ssh-overrides.zsh".source = ../zsh/ssh-overrides.zsh;
}
