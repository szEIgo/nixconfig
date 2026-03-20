# Virtualization

VMs, MicroVMs, and Kubernetes on mothership.

**Navigation:** [README](../README.md) | [Usage](usage.md) | [ZFS](zfs.md) | [Structure](structure.md)

---

## Architecture Overview

```
mothership
├── libvirt (KVM/QEMU)
│   ├── win11-nvidia     # Windows 11 + NVIDIA GPU
│   ├── win11-amd        # Windows 11 + AMD GPU
│   ├── win11-goldenImage
│   └── archlinux
│
├── MicroVMs (cloud-hypervisor)
│   ├── k3s-worker-1 (10.100.0.11)
│   ├── k3s-worker-2 (10.100.0.12)
│   └── k3s-worker-3 (10.100.0.13)
│
└── K3s (control plane: 10.100.0.1:6443)
    └── Workers join via microvm bridge
```

---

## Libvirt VMs

### Available VMs

| VM | GPU | Storage | Notes |
|----|-----|---------|-------|
| `win11-nvidia` | NVIDIA | ZFS zvol | Gaming, CUDA |
| `win11-amd` | AMD | ZFS zvol | General use |
| `win11-goldenImage` | None | Template | Base image |
| `archlinux` | None | qcow2 | Development |

### Commands

```bash
# List all VMs
make vm-list

# Start VM
make vm-start VM=win11-nvidia

# Stop VM (graceful)
make vm-stop VM=win11-nvidia

# Console
make vm-console VM=win11-nvidia

# Force stop
virsh destroy win11-nvidia
```

### GPU Passthrough

VMs use VFIO for GPU passthrough. The kernel params in `configuration.nix` bind GPUs to vfio-pci at boot.

```bash
# After VM shutdown, reset AMD GPU
make gpu-reset

# Check VFIO bindings
lspci -nnk | grep -A3 NVIDIA
lspci -nnk | grep -A3 AMD
```

### USB Passthrough

```bash
# Attach USB to running VM
make usb-attach VM=win11-nvidia

# List USB devices
lsusb
```

### Specialisations

Boot into different GPU configurations via specialisations:

| Specialisation | Description |
|---------------|-------------|
| `dualGpu` | Both GPUs available to host |
| `amd` | AMD GPU to host, NVIDIA to VFIO |
| `nvidia` | NVIDIA to host, AMD to VFIO |

Select at boot via systemd-boot menu.

---

## MicroVMs

Lightweight VMs for k3s workers using cloud-hypervisor.

### Network

```
microvm bridge (10.100.0.1/24)
├── k3s-worker-1: 10.100.0.11
├── k3s-worker-2: 10.100.0.12
└── k3s-worker-3: 10.100.0.13
```

### Storage

Each worker has a ZFS zvol at `fastPool/microvm/k3s-worker-{1,2,3}`.

```bash
# Initialize (first time only)
make microvm-init-zfs

# Check volumes
zfs list -r fastPool/microvm

# Resize
make microvm-resize ID=1 SIZE=20G
```

### Boot Flow

MicroVMs don't auto-start (ZFS is encrypted).

```bash
# After reboot:
make mount              # Import/decrypt pools
make microvm-start      # Start all VMs
```

### Commands

```bash
# List VMs
make microvm-list

# Status
make microvm-status
make microvm-status VM=k3s-worker-1

# Start/stop
make microvm-start VM=k3s-worker-1
make microvm-stop VM=k3s-worker-1

# SSH via VSOCK
make microvm-ssh VM=k3s-worker-1

# Restart all
make microvm-restart VM=all
```

### Configuration

MicroVMs are defined in `modules/virtualization/microvm/default.nix`.

Each worker:
- 2 vCPU, 2GB RAM
- Joins k3s cluster automatically
- Gets token via virtiofs share

---

## Kubernetes (k3s)

### Architecture

- **Control plane:** mothership (10.100.0.1)
- **Workers:** MicroVMs (10.100.0.11-13)
- **Networking:** Flannel VXLAN

### Initial Setup

```bash
# After first boot, copy kubeconfig
make k3s-init

# Verify cluster
kubectl get nodes
```

### Status

```bash
make k3s-status
```

Shows: service status, nodes, pods, services.

### Flux CD

GitOps with Flux:

```bash
# Create sops-age secret for decryption
make k3s-flux-init

# Bootstrap Flux
make k3s-flux-bootstrap

# Status
make k3s-flux-status

# Force reconcile
make k3s-flux-reconcile
make k3s-flux-reconcile TARGET=flux-system
```

### Wipe Cluster

```bash
# Stop k3s
make k3s-wipe

# Wipe and prevent restart
make k3s-wipe ARGS=--mask
```

---

## Podman

Container runtime (Docker-compatible).

```bash
# Run container
podman run -it alpine

# List containers
podman ps -a

# Compose
podman-compose up -d
```

Configuration in `modules/virtualization/podman.nix`.

---

## Files Reference

| Path | Purpose |
|------|---------|
| `modules/virtualization/libvirt.nix` | KVM/QEMU, VFIO hooks, polkit |
| `modules/virtualization/vms/` | NixVirt VM definitions |
| `modules/virtualization/vms/xml/` | Libvirt XML configs |
| `modules/virtualization/microvm/` | MicroVM host + guest config |
| `modules/virtualization/k3s.nix` | K3s control plane |
| `modules/virtualization/podman.nix` | Container runtime |

---

**See also:** [ZFS](zfs.md) | [Usage](usage.md) | [Structure](structure.md)
