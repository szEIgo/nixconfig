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

  # Ensure k3s waits for the token to be decrypted by sops-nix
  systemd.services.k3s = {
    after = [ "sops-nix.service" ];
    requires = [ "sops-nix.service" ];
  };

  # Clean up stale k3s state when the role changes (e.g. agent → server)
  # Without this, leftover agent/server data prevents k3s from starting after a role switch.
  systemd.services.k3s-role-guard = {
    description = "Clean stale k3s state on role change";
    wantedBy = [ "k3s.service" ];
    before = [ "k3s.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = let
      desiredRole = cfg.k3sRole;
      markerPath = "/var/lib/rancher/k3s/.nixos-role";
    in ''
      MARKER="${markerPath}"
      DESIRED="${desiredRole}"

      if [ -f "$MARKER" ]; then
        CURRENT=$(cat "$MARKER")
        if [ "$CURRENT" != "$DESIRED" ]; then
          echo "k3s role changed from $CURRENT to $DESIRED — cleaning stale state"
          systemctl stop k3s.service 2>/dev/null || true
          rm -rf /var/lib/rancher/k3s/agent
          rm -rf /var/lib/rancher/k3s/server
          echo "Stale k3s state removed"
        fi
      else
        echo "No role marker found — first boot or fresh install"
        mkdir -p /var/lib/rancher/k3s
      fi

      echo "$DESIRED" > "$MARKER"
    '';
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
