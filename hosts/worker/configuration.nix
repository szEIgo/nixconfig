{ config, lib, pkgs, ... }:

let
  cfg = config.local.worker;
  isServer = cfg.k3sRole == "server";
in {
  imports = [
    ../../modules/common/zsh.nix
    ../../modules/common/keepalived.nix
    ../../remote/ssh.nix
  ];

  # Pull pre-built closures from mothership's binary cache over LAN
  nix.settings = {
    substituters = [ "http://192.168.2.62:5000" ];
    trusted-public-keys = [
      "mothership-cache:ueAfPbTM17oSna34mKcFuebjFhORbzr0dvSuBM6vJFI="
    ];
  };

  # Required when Home Manager is installed via NixOS module with useUserPackages
  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

  environment.sessionVariables = {
    EDITOR = "vim";
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };

  # Users — passwords from sops for emergency console access
  users.defaultUserShell = pkgs.zsh;
  users.users.root.hashedPasswordFile = config.sops.secrets.user_password_hash.path;
  users.users.joni.hashedPasswordFile = config.sops.secrets.user_password_hash.path;

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

  # Ensure k3s waits for the token file to exist before starting
  systemd.services.k3s-wait-token = {
    description = "Wait for k3s token";
    wantedBy = [ "k3s.service" ];
    before = [ "k3s.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for i in $(seq 1 30); do
        if [ -f /run/secrets/k3s_token ]; then
          echo "k3s token found"
          exit 0
        fi
        sleep 1
      done
      echo "k3s token found at /run/secrets/k3s_token (via symlink from /etc/k3s/token)"
    '';
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

  # TODO: Impermanence disabled — needs proper setup where /etc is handled correctly.
  # The ZFS root rollback approach wipes NixOS-managed /etc symlinks (sshd_config, etc.)
  # before activation can recreate them. Revisit with a dedicated /persist dataset layout.
  #
  # Mark persist as neededForBoot for when impermanence is re-enabled
  fileSystems."/persist".neededForBoot = true;

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
