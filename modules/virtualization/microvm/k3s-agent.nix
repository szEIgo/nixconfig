# k3s Agent Configuration for MicroVM Workers
#
# Base NixOS configuration for k3s worker nodes running as MicroVMs.
# These agents join the mothership k3s server at 10.100.0.1:6443.

{ config, lib, pkgs, ... }:

{
  options.microvm.workerId = lib.mkOption {
    type = lib.types.int;
    description = "Worker ID number (1-9), used for IP addressing";
  };

  config = {
    # Minimal system for k3s agent
    system.stateVersion = "25.11";
    time.timeZone = "Europe/Copenhagen";

    # Use systemd-networkd for network configuration
    systemd.network.enable = true;
    networking.useNetworkd = true;
    networking.useDHCP = false;

    # NFS client support for democratic-csi storage
    boot.supportedFilesystems = [ "nfs" ];

    # Kernel tuning for Kubernetes workloads
    boot.kernel.sysctl = {
      # Required for containers that use inotify (log collectors, watchers)
      "fs.inotify.max_user_watches" = 524288;
      "fs.inotify.max_user_instances" = 524288;
      # Required by Elasticsearch/OpenSearch if ever needed
      "vm.max_map_count" = 262144;
      # Pod networking
      "net.ipv4.ip_forward" = true;
    };

    # k3s agent service
    services.k3s = {
      enable = true;
      role = "agent";
      serverAddr = "https://10.100.0.1:6443";
      tokenFile = "/run/secrets/k3s-token";
      extraFlags = [
        "--node-ip=10.100.0.1${toString config.microvm.workerId}"
        "--node-label=k3s.io/role=worker"
        "--node-label=node-type=microvm"
        "--node-label=node-id=worker-${toString config.microvm.workerId}"
      ];
    };

    # Container runtime dependencies
    virtualisation.containerd.enable = true;

    # Minimal packages for a worker node
    environment.systemPackages = with pkgs; [
      curl
      htop
      iproute2
      nfs-utils
    ];

    # Enable SSH for debugging (optional, can be removed in production)
    services.openssh = {
      enable = true;
      settings.PermitRootLogin = "prohibit-password";
    };

    # Firewall - allow kubelet and flannel
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        10250 # kubelet
      ];
      allowedUDPPorts = [
        8472 # flannel VXLAN
      ];
    };

    # Time synchronization
    services.timesyncd.enable = true;

    # Memory management - zram swap as safety net for OOM
    # memoryPercent=25 gives ~1GB compressed swap from ~250MB RAM overhead
    zramSwap.enable = true;
    zramSwap.algorithm = "zstd";
    zramSwap.memoryPercent = 25;

    # Journal storage (minimal)
    services.journald.extraConfig = ''
      SystemMaxUse=100M
      RuntimeMaxUse=50M
    '';
  };
}
