#!/usr/bin/env bash

cat << 'EOF'
NixConfig Management Commands

NIXOS
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
  make install                 Interactive NixOS install (from live ISO)
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
  make k3s-init                Copy kubeconfig to ~/.kube/config
  make k3s-status              Show k3s service, nodes, and pods
  make k3s-wipe [ARGS=...]     Wipe k3s state (--mask to prevent restart)

  Flux CD:
  make k3s-flux-init           Create sops-age secret for Flux decryption
  make k3s-flux-bootstrap      Bootstrap Flux CD from flux-system repo
  make k3s-flux-status         Show Flux sources, kustomizations, releases
  make k3s-flux-reconcile [TARGET=all]  Force reconcile

MICROVMS
  make microvm-list            List all MicroVMs and status
  make microvm-status [VM=]    Show detailed status (all or specific)
  make microvm-start [VM=]     Start MicroVM (all if omitted)
  make microvm-stop VM=...     Stop MicroVM (or VM=all)
  make microvm-restart VM=...  Restart MicroVM (or VM=all)
  make microvm-ssh VM=...      SSH into MicroVM via VSOCK
  make microvm-init-zfs        Create ZFS volumes for MicroVMs
  make microvm-destroy-zfs     Destroy ZFS volumes (DANGER!)
  make microvm-resize ID=1 SIZE=20G  Resize ZFS volume

DOCUMENTATION
  See docs/ folder or README.md for detailed guides.
EOF
