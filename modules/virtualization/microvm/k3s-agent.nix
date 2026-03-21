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

    # Use systemd-networkd for network configuration
    systemd.network.enable = true;
    networking.useNetworkd = true;
    networking.useDHCP = false;

    # k3s agent service
    services.k3s = {
      enable = true;
      role = "agent";
      serverAddr = "https://10.100.0.1:6443";
      tokenFile = "/run/secrets/k3s-token";
      extraFlags = [
        "--node-ip=10.100.0.1${toString config.microvm.workerId}"
        "--node-label=k3s.io/role=worker"
      ];
    };

    # Container runtime dependencies
    virtualisation.containerd.enable = true;

    # Minimal packages for debugging
    environment.systemPackages = with pkgs; [
      curl
      htop
      iproute2
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

    # Journal storage (minimal)
    services.journald.extraConfig = ''
      SystemMaxUse=100M
      RuntimeMaxUse=50M
    '';
  };
}
