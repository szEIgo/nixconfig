{ config, pkgs, lib, ... }: {
  networking.firewall.allowedUDPPorts = [ 51821 ];

  networking.wg-quick.interfaces.wg0 = {
    address = [ "192.168.10.5/24" ];
    dns = [ "192.168.10.1" ];
    privateKeyFile = "/etc/secrets/t480_wg_private.key";

    peers = [
      {
        # mothership — route all traffic through VPN
        publicKey = "vL6bB4f9ELSQc3OvDPWzFq5eEioUufxNvoqcUp/VX3U=";
        endpoint = "80.209.114.19:51821";
        allowedIPs = [ "0.0.0.0/0" ];
        persistentKeepalive = 25;
      }
    ];
  };
}
