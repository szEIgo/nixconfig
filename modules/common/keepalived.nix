# Floating VIP for k3s ingress + DNS HA
# One control-plane node holds 192.168.2.200 at a time.
# If it dies, another takes over within ~3 seconds.
# The VIP serves: Traefik (80/443), Blocky DNS (53)
# UniFi port-forwards 80/443 to the VIP.
# UniFi DHCP DNS set to the VIP.
{ config, lib, pkgs, ... }:

let
  cfg = config.local.worker;
  vip = "192.168.2.200";
in {
  options.local.worker.keepalivedPriority = lib.mkOption {
    type = lib.types.int;
    default = 100;
    description = "VRRP priority — highest wins the VIP";
  };

  options.local.worker.keepalivedInterface = lib.mkOption {
    type = lib.types.str;
    default = "enp0s31f6";
    description = "Network interface for the VIP";
  };

  config = lib.mkIf (cfg.k3sRole == "server") {
    # --- Keepalived: floating VIP ---
    services.keepalived = {
      enable = true;
      vrrpInstances.k3s-ingress = {
        interface = cfg.keepalivedInterface;
        state = "BACKUP";
        virtualRouterId = 51;
        priority = cfg.keepalivedPriority;
        virtualIps = [
          { addr = "${vip}/24"; }
        ];
      };
    };

    # --- Blocky: DNS with ad-blocking + *.szigethy.lan ---
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
          "szigethy.lan" = vip;
        };

        caching = {
          minTime = "5m";
          maxTime = "30m";
          prefetching = true;
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 53 ];
    networking.firewall.allowedUDPPorts = [ 53 ];
    networking.firewall.extraCommands = ''
      iptables -A INPUT -p vrrp -j ACCEPT
    '';
  };
}
