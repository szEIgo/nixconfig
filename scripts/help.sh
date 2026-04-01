#!/usr/bin/env bash

cat << 'EOF'
NixConfig Management Commands

DEPLOYMENT (deploy-rs with automatic rollback)
  make deploy HOST=...           Deploy to a single node (e.g. carrier-tc1)
  make deploy-all                Deploy to all fleet nodes
  make deploy-new HOST=... IP=.. Provision a new node via nixos-anywhere

NIXOS (local rebuild)
  make switch [HOST=...] [SPEC=...]  Build and switch to configuration
                               SPEC: amd (default), nvidia, dualGpu, base
  make switch-interactive      Interactive menu to choose specialisation
  make build [HOST=...]        Build without switching
  make test [HOST=...]         Build and activate without bootloader entry
  make update [HOST=...]       Update flake inputs and rebuild
  make gc [DAYS=30]            Garbage collect old generations

  Memory control (env vars):
    NIX_JOBS=2                 Max parallel builds (default: 2)
    NIX_CORES=8                Cores per build (default: 8)
    Example: NIX_JOBS=4 NIX_CORES=4 make switch

INSTALL & BOOTSTRAP
  make worker-iso              Build custom installer ISO
  make flash-worker-iso        Flash installer ISO to USB
  make bootstrap               Decrypt master key for new machine setup
  make cleanup                 Securely delete temporary master key

SECRETS & SSH KEYS
  make add-host-keys HOST=... IP=...  Generate SSH keys and add SOPS for a host
  make secrets-edit            Edit encrypted secrets
  make secrets-updatekeys      Re-encrypt for all hosts
  make secrets-list            Show which secrets are stored

STORAGE (ZFS)
  make mount                   Import and decrypt ZFS pools
  make zfs-status              Show pool and dataset status
  make zfs-scrub               Start integrity scrub on all pools
  make zfs-snapshot DATASET=.. Create timestamped snapshot

VIRTUAL MACHINES (LIBVIRT)
  make vm-list                 List all libvirt VMs
  make vm-start VM=...         Start a VM
  make vm-stop VM=...          Graceful shutdown
  make vm-console VM=...       Attach to VM console
  make vm-fix-efi VM=...       Remove EFI entries from VM config
  make vnc                     Start headless KDE with VNC

HARDWARE
  make gpu-reset               Reset AMD GPU (PCI rescan)
  make usb-attach VM=...       Attach USB devices to VM

KUBERNETES (K3S)
  make k3s-status              Show k3s service, nodes, and pods
  make k3s-wipe [ARGS=...]     Wipe k3s state (--mask to prevent restart)

  Flux CD:
  make k3s-flux-init           Create sops-age secret for Flux decryption
  make k3s-flux-bootstrap      Bootstrap Flux CD from flux-system repo
  make k3s-flux-status         Show Flux sources, kustomizations, releases
  make k3s-flux-reconcile [TARGET=all]  Force reconcile

WIREGUARD VPN
  make wg-connect              Connect to mothership VPN (clients only)
  make wg-disconnect           Disconnect from VPN (clients only)
  make wg-status               Show WireGuard interface status

FLEET NODES
  Carriers (control plane):     Interceptors (workers):
    mothership  192.168.2.62      interceptor-nuc1  192.168.2.102
    carrier-tc1 192.168.2.192     interceptor-tc1   192.168.2.238
    carrier-tc2 192.168.2.250     interceptor-tc2   192.168.2.147

DOCUMENTATION
  See docs/ folder for detailed guides.
EOF
