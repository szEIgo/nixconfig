# NixOS system-level zsh configuration
# User shell config is managed by home-manager (home/shell/default.nix)
# This module only handles system-wide defaults and root user setup
{ config, lib, pkgs, ... }:

{
  # Enable zsh system-wide
  programs.zsh.enable = true;

  # Provide p10k config for root so it gets the same styled prompt
  system.activationScripts.rootP10k = lib.stringAfter [ "users" ] ''
    cp ${../../home/configs/p10k.zsh} /root/.p10k.zsh
    chmod 644 /root/.p10k.zsh
  '';

  # Minimal root shell setup (full config is in home-manager)
  programs.zsh.interactiveShellInit = ''
    # Powerlevel10k for root
    source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
    [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
  '';
}
