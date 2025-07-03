{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.rke2 ];
  services.rke2.enable = true;
  services.rke2.role = "server";

  services.rke2.config = {
    "cni" = "canal";
    # This tells RKE2 to manage its own TLS certificates.
    "tls-san" = [ config.networking.hostName ]; 
  };

  # 5. Open the necessary firewall ports for the server
  networking.firewall.allowedTCPPorts = [
    6443 # Kubernetes API
    2379 # etcd client
    2380 # etcd peer
    10250 # Kubelet
  ];
  networking.firewall.allowedUDPPorts = [
    8472 # Canal/Flannel CNI
  ];
}
