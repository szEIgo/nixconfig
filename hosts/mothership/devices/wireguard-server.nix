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
          MTUBytes = "1420"; # A standard safe MTU for WireGuard
        };
        wireguardConfig = {
          PrivateKeyFile =
            "/etc/secrets/mothership_wg_private.key"; # Or config.age.secrets...
          ListenPort = 51821;
        };

        # --- CORRECTED PEERS SECTION ---
        wireguardPeers = [
          {
            PublicKey = "8Ep60nleomY9Yp2fYKDCwR1YeGyTdkeh+o2DjVnJVGU=";
            # Only list the IP this client is allowed to have.
            # Use /32 for a single IP address.
            AllowedIPs = [ "192.168.10.2/32" ];
            # PersistentKeepalive is a client-side setting to keep NAT open.
            # It's not typically needed on the server's peer config.
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
      # The server's own IP on the tunnel.
      address = [ "192.168.10.1/24" ];
      # This ensures networkd waits for the interface to be ready.
      linkConfig.RequiredForOnline = "routable";
    };
  };
}
