{ config, lib, pkgs, ... }:

{
  systemd.network = {
    enable = true;

    networks."enp6s0" = {
      matchConfig.Name = "enp6s0";
      address = [ "192.168.2.62/24" ];

      routes = [
        {
          Gateway = "192.168.2.1";
        }
      ];
      linkConfig.RequiredForOnline = "routable";
    };
  };

  services.resolved = {
    enable = true;
  };
  services.resolved.extraConfig = ''
    DNSStubListener=no
  '';
}
