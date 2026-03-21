# Static network configuration for the Intel NUC
#
# TODO: Verify the interface name (eno1) matches the actual NUC hardware.
#       Common Intel NUC interface names: eno1, enp0s25, enp1s0.
#       Check with `ip link` on the NUC.
{
  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "eno1";
      address = [ "192.168.2.211/24" ];
      networkConfig = {
        DNS = [ "1.1.1.1" "8.8.8.8" ];
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
      };
    };
  };
}
