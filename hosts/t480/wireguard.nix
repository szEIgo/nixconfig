{ config, pkgs, lib, ... }: {
  networking.firewall.allowedUDPPorts = [ 51821 ];

  networking.wg-quick.interfaces.wg0 = {
    address = [ "192.168.10.5/24" ];
    privateKeyFile = "/etc/secrets/t480_wg_private.key";

    peers = [
      {
        # mothership
        publicKey = "vL6bB4f9ELSQc3OvDPWzFq5eEioUufxNvoqcUp/VX3U=";
        endpoint = "192.168.2.62:51821";
        allowedIPs = [ "192.168.10.0/24" ];
        persistentKeepalive = 25;
      }
    ];
  };
}
