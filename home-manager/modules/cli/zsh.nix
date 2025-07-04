# ./home-manager/modules/cli/zsh.nix
{ pkgs, ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      l = "eza --icons";
      la = "eza --icons -a";
      ll = "eza --icons -lah";
      ls = "eza --icons";
      cat = "bat --style=plain --pager=never";
      vim = "hx";
      docker = "podman";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "vi-mode" "history" "colorize" "aws" "kubectl" "terraform" ];
      theme = ""; # We source p10k manually for more control
    };
    initExtra = ''
      # Powerlevel10k theme
      source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

      # SDKMAN - This part remains manual as it modifies the environment at runtime
      export SDKMAN_DIR="$HOME/.sdkman"
      [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
    '';
  };

  programs.keychain = {
    enable = true;
    keys = [ "id_ecdsa" ]; # Add any other keys you want managed
  };
}
