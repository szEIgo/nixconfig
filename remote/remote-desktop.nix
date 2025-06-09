{ config, lib, pkgs, ... }:
{
    services =  {
      xrdp.enable = true;
      xrdp.defaultWindowManager = "Hyprland";
      xrdp.openFirewall = true;
   };
}
