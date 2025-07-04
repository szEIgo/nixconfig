# ./nixos/modules/services/wireguard-server.nix
{ ... }: {
  # This uses systemd-networkd, which is already enabled in common.nix
  systemd.network.netdevs."50-wg0" = {
    netdevConfig = {
      Kind = "wireguard";
      Name = "wg0";
      MTUBytes = "1420";
    };
    wireguardConfig = {
      PrivateKeyFile = "/etc/secrets/mothership_wg_private.key"; # Assumes you place secrets here
      ListenPort = 5664;
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
        AllowedIPs = [ "192.168.10.4/32" ]; # Use /32 for single IPs
      }
    ];
  };

  systemd.network.networks."wg0" = {
    matchConfig.Name = "wg0";
    address = [ "192.168.10.1/24" ];
    linkConfig.RequiredForOnline = "routable";
  };

  # Set up NAT for WireGuard clients
  networking.nat = {
    enable = true;
    externalInterface = "enp6s0";
    internalInterfaces = [ "wg0" ];
  };
}
