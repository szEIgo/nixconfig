{ config, lib, pkgs, ... }:

let
  joniHome = config.users.users.joni.home or "/home/joni";
  cluster = import ../cluster-config.nix;

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

        deployment:
          kind: DaemonSet

        ports:
          web:
            nodePort: 30080
            hostPort: 80
          websecure:
            nodePort: 30443
            hostPort: 443
          gitlab-ssh:
            port: 2222
            exposedPort: 2222
            hostPort: 2222
            protocol: TCP

        tolerations:
          - key: "node-role.kubernetes.io/control-plane"
            operator: "Exists"
            effect: "NoSchedule"
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

  # Pull-through cache: k3s mirrors Docker Hub via local registry
  environment.etc."rancher/k3s/registries.yaml".text = ''
    mirrors:
      docker.io:
        endpoint:
          - "http://registry.registry-system.svc.cluster.local:5000"
  '';

  # Kernel tuning for k3s + microvms (many watchers across containers and VMs)
  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 524288;
    "fs.inotify.max_user_watches" = 524288;
  };

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = [
      "--cluster-init"
      "--disable local-storage"
      "--write-kubeconfig-mode=0640"
      "--write-kubeconfig-group=wheel"
      "--node-label=node-id=mothership"
      "--node-label=node.kubernetes.io/size=large"
      "--node-taint=node-role=desktop:PreferNoSchedule"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 6443 2379 2380 30080 30443 80 443 2222 ];
  networking.firewall.allowedUDPPorts = [ 8472 ];
  networking.firewall.extraCommands = ''
    iptables -A INPUT -p vrrp -j ACCEPT
  '';

  # Floating VIP for ingress HA — mothership has highest priority
  services.keepalived = {
    enable = true;
    vrrpInstances.k3s-ingress = {
      interface = "enp6s0";
      state = "BACKUP";
      virtualRouterId = 51;
      priority = 200;
      virtualIps = [
        { addr = "${cluster.vip}/24"; }
      ];
    };
  };

}
