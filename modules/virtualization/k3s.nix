{ config, pkgs, ... }:

{
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags =
      [ "--disable traefik" "--disable servicelb" "--disable local-storage" ];
  };

  networking.firewall.allowedTCPPorts = [ 6443 ];
  networking.firewall.allowedUDPPorts = [ 8472 ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.netfilter.nf_conntrack_max" = 131072;
  };

  environment.systemPackages = with pkgs; [ kubernetes.kubectl ];
  environment.etc."kubeconfig".source = config.services.k3s.kubeconfig;
  environment.sessionVariables = { KUBECONFIG = "/etc/kubeconfig"; };
}
