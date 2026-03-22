{ config, lib, pkgs, ... }:

let
  joniHome = config.users.users.joni.home or "/home/joni";

  traefikGatewayApiHelmChartConfig = ''
    apiVersion: helm.cattle.io/v1
    kind: HelmChartConfig
    metadata:
      name: traefik
      namespace: kube-system
    spec:
      valuesContent: |-
        providers:
          kubernetesGateway:
            enabled: true

        service:
          type: NodePort

        ports:
          web:
            nodePort: 30080
          websecure:
            nodePort: 30443
  '';
in
{


  environment.variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

  systemd.tmpfiles.rules = [
    # Point common sbin paths to NixOS zfs binary
    "L /sbin/zfs - - - - /run/current-system/sw/bin/zfs"
    "L /usr/sbin/zfs - - - - /run/current-system/sw/bin/zfs"
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"

    # Ensure k3s will pick up Traefik Gateway API config via Helm Controller
    "d /var/lib/rancher/k3s/server/manifests 0755 root root -"
    "L+ /var/lib/rancher/k3s/server/manifests/traefik-config.yaml - - - - /etc/k3s/manifests/traefik-config.yaml"

    # Make plain `kubectl` work for user 'joni' without any manual steps.
    # This keeps the kubeconfig in one place (written by k3s) and links the usual kubectl path to it.
    "d ${joniHome}/.kube 0700 joni joni -"
    "L+ ${joniHome}/.kube/config - - - - /etc/rancher/k3s/k3s.yaml"
  ];

  environment.etc."k3s/manifests/traefik-config.yaml".text =
    traefikGatewayApiHelmChartConfig;


  # Kernel tuning for k3s + microvms (many watchers across containers and VMs)
  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 524288;
    "fs.inotify.max_user_watches" = 524288;
  };

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = [
      "--disable local-storage"
      "--write-kubeconfig-mode=0640"
      "--write-kubeconfig-group=wheel"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 6443 30080 30443 ];
  networking.firewall.allowedUDPPorts = [ 8472 ];

}
