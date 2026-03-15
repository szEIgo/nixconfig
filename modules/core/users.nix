# User configuration: primary user setup
{ config, lib, pkgs, ... }:

{
  users.groups.joni = {};

  users.users.joni = {
    isNormalUser = true;
    group = "joni";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  users.defaultUserShell = pkgs.zsh;
}
