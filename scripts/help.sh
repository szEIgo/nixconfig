#!/usr/bin/env bash

cat << 'EOF'
NixOS Configuration Management

NIXOS
  make switch [HOST=...]     Build and switch to configuration
  make build [HOST=...]      Build without switching
  make test [HOST=...]       Build and activate without bootloader entry
  make update [HOST=...]     Update flake inputs and rebuild
  make gc [DAYS=30]          Garbage collect old generations

  Memory control (env vars):
    NIX_JOBS=2               Max parallel builds (default: 2)
    NIX_CORES=8              Cores per build (default: 8)
    GC_INITIAL_HEAP_SIZE     Evaluator heap limit in bytes (default: 8GB)
    Example: NIX_JOBS=4 NIX_CORES=4 make switch

BOOTSTRAP
  make bootstrap             Decrypt master key for new machine setup
  make cleanup               Securely delete temporary master key

SECRETS
  make secrets-edit          Edit encrypted secrets
  make secrets-updatekeys    Re-encrypt for all hosts

HARDWARE
  make gpu-reset             Reset AMD GPU (PCI rescan)
  make usb-attach [VM=...]   Attach USB devices to VM

K3S
  make k3s-init              Copy kubeconfig to ~/.kube/config
  make k3s-status            Show k3s service, nodes, and pods
  make k3s-wipe [ARGS=...]   Wipe k3s state (--mask to prevent restart)

K3S FLUX
  make k3s-flux-init         Create sops-age secret for Flux decryption
  make k3s-flux-bootstrap    Bootstrap Flux CD from flux-system repo
  make k3s-flux-status       Show Flux sources, kustomizations, releases
  make k3s-flux-reconcile [TARGET=all]  Force reconcile (all|sources|<name>)

VM
  make vm-fix-efi [VM=...]   Remove EFI entries from VM config
  make vnc                   Start headless KDE with VNC

STORAGE
  make mount                 Import and mount ZFS pools

MICROVM
  make microvm-list          List all MicroVMs and status
  make microvm-status [VM=]  Show detailed status (all or specific)
  make microvm-start [VM=]   Start MicroVM (all if omitted)
  make microvm-stop VM=...   Stop MicroVM (or VM=all)
  make microvm-restart VM=.. Restart MicroVM (or VM=all)
  make microvm-ssh VM=...    SSH into MicroVM via VSOCK
  make microvm-init-zfs      Create ZFS volumes for MicroVMs
  make microvm-destroy-zfs   Destroy ZFS volumes (DANGER!)
  make microvm-resize ID=1 SIZE=20G  Hot-resize ZFS volume
EOF
