{ config, lib, pkgs, ... }:
{
    services =  {
      xrdp.enable = true;
      xrdp.defaultWindowManager = "startplasma-x11";
      xrdp.openFirewall = true;
   };
}
