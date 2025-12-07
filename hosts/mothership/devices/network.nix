# In your network.nix file
{
  systemd.network = {
      enable = true;
    networks."enp6s0" = {
      matchConfig.Name = "enp6s0";
      address = [ "192.168.2.62/24" ]; 
      networkConfig = {
        DNS = [ "1.1.1.1" "8.8.8.8" ];
      };
      routes = [{ Gateway = "192.168.2.1"; }];
      linkConfig.RequiredForOnline = "routable";
    };
  };
    services.resolved = {
      enable = true;
      extraConfig = ''
        DNSStubListener=no
      '';
    };
}