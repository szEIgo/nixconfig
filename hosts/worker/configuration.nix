{ config, lib, pkgs, ... }:

let
  cfg = config.local.worker;
  isServer = cfg.k3sRole == "server";
in {
  imports = [
    ../../modules/common/zsh.nix
    ../../remote/ssh.nix
  ];

  # Required when Home Manager is installed via NixOS module with useUserPackages
  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

  environment.sessionVariables = {
    EDITOR = "vim";
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };

  # Users
  users.defaultUserShell = pkgs.zsh;

  # k3s node joining the mothership cluster
  services.k3s = {
    enable = true;
    role = cfg.k3sRole;
    serverAddr = "https://192.168.2.62:6443";
    tokenFile = "/etc/k3s/token";
    extraFlags = [
      "--node-label=node-id=${config.networking.hostName}"
      "--node-label=node.kubernetes.io/size=${cfg.nodeSize}"
    ] ++ lib.optionals isServer [
      "--disable local-storage"
    ];
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22    # SSH
      10250 # kubelet
    ] ++ lib.optionals isServer [
      6443  # k3s API server
      2379  # etcd client
      2380  # etcd peer
    ];
    allowedUDPPorts = [
      8472  # flannel VXLAN
      51821 # WireGuard
    ];
  };

  # Networking
  networking.useDHCP = true;

  # Memory management
  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";

  # Ignore power/lid events (headless server)
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    IdleAction = "ignore";
  };

  # Pull-through cache: k3s mirrors Docker Hub via local registry
  environment.etc."rancher/k3s/registries.yaml".text = ''
    mirrors:
      docker.io:
        endpoint:
          - "http://registry.registry-system.svc.cluster.local:5000"
  '';

  # NFS client support for democratic-csi storage
  boot.supportedFilesystems = [ "nfs" ];

  # Minimal packages
  environment.systemPackages = with pkgs; [
    curl
    htop
    iproute2
    vim
    nfs-utils
  ];

  system.stateVersion = "25.11";
}
