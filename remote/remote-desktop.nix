{ config, lib, pkgs, ... }:
{
    services =  {
      xrdp.enable = true;
      xrdp.defaultWindowManager = "Hyprland";
      xrdp.openFirewall = true;
   };
  #systemd.services.xrdp = {
  #  wantedBy = [ "multi-user.target" ];
  #  serviceConfig.ExecStart = "${pkgs.xrdp}/bin/xrd
  p";
  #};
}
