# In your network.nix file
{
  systemd.network = {
      enable = true;
    networks."enp6s0" = {
      matchConfig.Name = "enp6s0";
      address = [ "192.168.2.62/24" ]; 
      networkConfig = {
        DNS = [ "192.168.2.200" ];
      };
      routes = [{ Gateway = "192.168.2.1"; }];
      linkConfig.RequiredForOnline = "routable";
    };
  };
    services.resolved = {
      enable = true;
      settings = {
        Resolve = {
          DNSStubListener = "no";
          FallbackDNS = "1.1.1.1 9.9.9.9";
        };
      };
    };
}