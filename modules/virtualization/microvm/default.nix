# MicroVM Host Configuration
#
# Provides lightweight VMs for k3s worker nodes using cloud-hypervisor.
# Workers join the existing k3s cluster on mothership (10.100.0.1:6443).

{ config, lib, pkgs, ... }:

let
  # Network configuration
  bridgeName = "microvm";
  bridgeAddress = "10.100.0.1";
  bridgeNetwork = "10.100.0.0/24";

  # ZFS pool for microvm volumes
  zfsPool = "fastPool";

  # Base configuration for k3s worker MicroVMs
  mkK3sWorker = { id, macAddress }: {
    autostart = true;
    restartIfChanged = true;

    config = { config, pkgs, ... }: {
      imports = [ ./k3s-agent.nix ];

      # Worker-specific settings
      networking.hostName = "k3s-worker-${toString id}";
      microvm.workerId = id;

      # Static IP: 10.100.0.1X where X is the worker ID
      # Match by MAC address since cloud-hypervisor uses virtio naming (enp*)
      systemd.network.networks."10-lan" = {
        matchConfig.MACAddress = macAddress;
        networkConfig = {
          Address = "10.100.0.1${toString id}/24";
          Gateway = bridgeAddress;
          DNS = [ "1.1.1.1" "8.8.8.8" ];
        };
      };

      microvm = {
        hypervisor = "cloud-hypervisor";
        vcpu = 2;
        mem = 2048; # 2GB RAM

        # vsock for systemd-notify (CID 3+ reserved for guests)
        vsock = {
          cid = 100 + id;
        };

        interfaces = [{
          type = "tap";
          id = "vm-k3s-${toString id}";
          mac = macAddress;
        }];

        # Shared directory for k3s token (read-only from host)
        shares = [{
          tag = "k3s-secrets";
          source = "/run/microvm-secrets";
          mountPoint = "/run/secrets";
          proto = "virtiofs";
        }];

        # Persistent storage for k3s data using ZFS zvol
        volumes = [{
          image = "/dev/zvol/${zfsPool}/microvm/k3s-worker-${toString id}";
          mountPoint = "/var/lib/rancher";
          autoCreate = false; # We manage ZFS volumes ourselves
        }];
      };
    };
  };

in {
  # Enable MicroVM host functionality
  microvm.host.enable = true;

  # Grant microvm user access to ZFS zvol block devices
  # The zvols are owned by root:disk, so microvm needs disk group membership
  users.users.microvm.extraGroups = [ "disk" ];

  # ZFS volumes for MicroVM persistent storage
  # Create parent dataset and zvols for each worker
  # Run manually once:
  #   sudo zfs create fastPool/microvm
  #   sudo zfs create -V 10G fastPool/microvm/k3s-worker-1
  #   sudo zfs create -V 10G fastPool/microvm/k3s-worker-2
  #   sudo zfs create -V 10G fastPool/microvm/k3s-worker-3
  #   sudo mkfs.ext4 /dev/zvol/fastPool/microvm/k3s-worker-1
  #   sudo mkfs.ext4 /dev/zvol/fastPool/microvm/k3s-worker-2
  #   sudo mkfs.ext4 /dev/zvol/fastPool/microvm/k3s-worker-3

  # Bridge network for MicroVMs
  systemd.network = {
    enable = true;
    netdevs."10-${bridgeName}" = {
      netdevConfig = {
        Kind = "bridge";
        Name = bridgeName;
      };
    };
    networks."10-${bridgeName}" = {
      matchConfig.Name = bridgeName;
      networkConfig = {
        Address = "${bridgeAddress}/24";
        ConfigureWithoutCarrier = true;
      };
      linkConfig.RequiredForOnline = "no";
    };
  };

  # Attach MicroVM tap interfaces to bridge
  systemd.network.networks."11-microvm" = {
    matchConfig.Name = "vm-*";
    networkConfig.Bridge = bridgeName;
  };

  # NAT for MicroVM internet access
  networking.nat = {
    enable = true;
    internalInterfaces = [ bridgeName ];
    # externalInterface is auto-detected
  };

  # Firewall rules for MicroVM network
  networking.firewall = {
    trustedInterfaces = [ bridgeName ];
    # Allow k3s API access from MicroVM network
    allowedTCPPorts = [ 6443 ];
  };

  # Forward flannel VXLAN traffic for k3s pod networking
  networking.firewall.allowedUDPPorts = [ 8472 ];

  # Create secrets directory for k3s token sharing
  systemd.tmpfiles.rules = [
    "d /run/microvm-secrets 0750 root root -"
  ];

  # Service to copy k3s token for MicroVMs
  systemd.services.microvm-k3s-token = {
    description = "Copy k3s token for MicroVM workers";
    wantedBy = [ "multi-user.target" ];
    after = [ "k3s.service" ];
    requires = [ "k3s.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "copy-k3s-token" ''
        # Wait for token to exist
        while [ ! -f /var/lib/rancher/k3s/server/token ]; do
          sleep 1
        done
        cp /var/lib/rancher/k3s/server/token /run/microvm-secrets/k3s-token
        chmod 0440 /run/microvm-secrets/k3s-token
      '';
    };
  };

  # Define k3s worker MicroVMs
  microvm.vms = {
    k3s-worker-1 = mkK3sWorker {
      id = 1;
      macAddress = "02:00:00:00:01:01";
    };
    # k3s-worker-2 = mkK3sWorker {
    #   id = 2;
    #   macAddress = "02:00:00:00:01:02";
    # };
    # k3s-worker-3 = mkK3sWorker {
    #   id = 3;
    #   macAddress = "02:00:00:00:01:03";
    # };
  };
}
