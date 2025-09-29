{ config, pkgs, lib, ... }: {
  networking = {
    useNetworkd = true;

    firewall = {
      # This is correct
      allowedTCPPorts = [ 22 47989 47990 ];
      allowedUDPPorts = [ 5664 47998 47999 48000 48002 48010 51821 ];
      trustedInterfaces =
        [ "wg0" "enp6s0" ]; # Keeping enp6s0 here can be a security risk
    };

    # This is correct
    nat = {
      enable = true;
      externalInterface = "enp6s0";
      internalInterfaces = [ "wg0" ];
    };
  };

  systemd.network = {
    netdevs = {
      "50-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
          MTUBytes = "1420";
        };
        wireguardConfig = {
          PrivateKeyFile =
            "/etc/secrets/mothership_wg_private.key"; 
          ListenPort = 51821;
        };

        wireguardPeers = [
          {
            PublicKey = "8Ep60nleomY9Yp2fYKDCwR1YeGyTdkeh+o2DjVnJVGU=";
            AllowedIPs = [ "192.168.10.2/32" ];
          }
          {
            PublicKey = "qNhTIq7VOu9/TPXAtgbIbPoxRfCimti+3xcaxicdiBY=";
            AllowedIPs = [ "192.168.10.3/32" ];
          }
          {
            PublicKey = "SOV6U1SR328Up+dP2t+04ErNiIDuD0qkCfa6+ffTrkU=";
            AllowedIPs = [ "192.168.10.4/32" ];
          }
        ];
      };
    };

    networks."wg0" = {
      matchConfig.Name = "wg0";
      address = [ "192.168.10.1/24" ];
      linkConfig.RequiredForOnline = "routable";
    };
  };
}
