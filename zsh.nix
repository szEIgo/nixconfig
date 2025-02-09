{ config, lib, pkgs, ... }:
{

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
    };

 #   history.size = 10000;
 #   history.ignoreAllDups = true;
 #   history.path = "/home/joni/.zsh_history";
 };

}
