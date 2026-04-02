# Mothership Blocky — same config as carriers (via keepalived module)
# but also listens on the WireGuard interface for VPN clients
{ config, pkgs, lib, ... }: {
  services.blocky = {
    enable = true;
    settings = {
      ports.dns = "0.0.0.0:53";

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
        clientGroupsBlock.default = [ "ads" "trackers" ];
        loading.refreshPeriod = "12h";
      };

      # Wildcard: all *.szigethy.lan → VIP (Traefik routes by Host header)
      customDNS.mapping = {
        "szigethy.lan" = "192.168.2.200";
      };

      caching = {
        minTime = "5m";
        maxTime = "30m";
        prefetching = true;
      };
    };
  };

  # Allow DNS on all interfaces (LAN + WireGuard)
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
