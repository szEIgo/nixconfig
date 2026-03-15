#!/usr/bin/env bash

cat << 'EOF'
NixOS Configuration Management

NIXOS
  make switch [HOST=...]     Build and switch to configuration
  make build [HOST=...]      Build without switching
  make test [HOST=...]       Build and activate without bootloader entry
  make update [HOST=...]     Update flake inputs and rebuild
  make gc [DAYS=30]          Garbage collect old generations

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
EOF
