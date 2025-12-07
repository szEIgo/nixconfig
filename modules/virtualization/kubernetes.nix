{ config, pkgs, ... }:
let
  kubeMasterIP = "192.168.2.62";
  kubeMasterHostname = "api.kube";
  kubeMasterAPIServerPort = 6443;
in
{
  networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";

  networking.firewall.trustedInterfaces = [ "flannel.0" ];

  environment.systemPackages = with pkgs; [
    kompose
    kubectl
    kubernetes
  ];

  services.kubernetes = {
    roles = ["master" "node"];
    masterAddress = kubeMasterHostname;
    apiserverAddress = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
    easyCerts = true;

    apiserver = {
      securePort = kubeMasterAPIServerPort;
      advertiseAddress = kubeMasterIP;
    };

    addons.dns.enable = true;

    kubelet.extraOpts = "--fail-swap-on=false";
  };
}