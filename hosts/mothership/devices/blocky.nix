{ config, pkgs, lib, ... }: {
  services.blocky = {
    enable = true;
    settings = {
      ports = {
        dns = "192.168.10.1:53";
      };

      upstreams.groups.default = [
        "https://one.one.one.one/dns-query"
        "https://dns.quad9.net/dns-query"
      ];

      bootstrapDns = [
        { upstream = "1.1.1.1"; }
        { upstream = "9.9.9.9"; }
      ];

      blocking = {
        denylists = {
          ads = [
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
            "https://adaway.org/hosts.txt"
          ];
          trackers = [
            "https://v.firebog.net/hosts/Easyprivacy.txt"
          ];
        };

        clientGroupsBlock = {
          default = [ "ads" "trackers" ];
        };

        loading = {
          refreshPeriod = "12h";
        };
      };

      caching = {
        minTime = "5m";
        maxTime = "30m";
        prefetching = true;
      };
    };
  };

  # Allow DNS on the WireGuard interface
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 53 ];
  networking.firewall.interfaces.wg0.allowedUDPPorts = [ 53 ];
}
