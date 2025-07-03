{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.rke2 ];
  services.rke2.enable = true;
  services.rke2.role = "server";

  services.rke2.extraFlags = [
    "--cni=canal"
    "--tls-san=${config.networking.hostName}"
  ];

  networking.firewall.allowedTCPPorts = [
    6443
    2379
    2380
    10250
  ];
  networking.firewall.allowedUDPPorts = [
    8472
  ];
}
