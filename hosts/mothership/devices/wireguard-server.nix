{ config, pkgs, lib, ... }:

{
  networking = {
    useNetworkd = true;
    firewall = {
      allowedUDPPorts = [ 5664 53 ];
      allowedTCPPorts = [ 53 ];
      allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
      allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
      trustedInterfaces = [ "wg0" ];
    };
  };

  systemd.network = {
    enable = true;

    netdevs."50-wg0" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
        MTUBytes = "1300";
      };
      wireguardConfig = {
        PrivateKeyFile = "/etc/secrets/mothership_wg_private.key";
        ListenPort = 5664;
        RouteTable = "main";
      };
      wireguardPeers = [
        {
          PublicKey = "8Ep60nleomY9Yp2fYKDCwR1YeGyTdkeh+o2DjVnJVGU=";
          AllowedIPs = [ "10.100.0.3/32" ];
        }
      ];
    };

    # Configure network settings for wg0
    networks."50-wg0" = {
      matchConfig.Name = "wg0";
      address = [ "10.100.0.1/24" ];
      networkConfig = {
        DHCP = "ipv4";
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

  systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";
}
