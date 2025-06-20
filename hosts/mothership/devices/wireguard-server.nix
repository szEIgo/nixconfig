{
  config,
  lib,
  pkgs,
  ...
}: {

  # enable NAT
  networking.nat.enable = true;
  networking.nat.externalInterface = "enp6s0";
  networking.nat.internalInterfaces = [ "wg0" ];
  networking.firewall = {
    allowedUDPPorts = [ 5664 ];
  };

  networking.wireguard.enable = true;
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.100.0.1/24" ];

      listenPort = 5664;

      postSetup = ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o enp6s0 -j MASQUERADE
      '';

      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o enp6s0 -j MASQUERADE
      '';
     
      privateKeyFile = "/etc/secrets/mothership-wg-private.key";

      peers = [
        { # John Doe
          publicKey = "{john doe's public key}";
          allowedIPs = [ "10.100.0.3/32" ];
        }
      ];
    };
  };
  ...
}