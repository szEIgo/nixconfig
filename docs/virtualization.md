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
│   ├── k3s-worker-1 (10.100.0.11, node-type=microvm)
│   ├── k3s-worker-2 (10.100.0.12, node-type=microvm)
│   └── k3s-worker-3 (10.100.0.13, node-type=microvm)
│
├── K3s (control plane: 10.100.0.1:6443)
│   └── MicroVM workers join via bridge, nuc joins via LAN
│
nuc (192.168.2.102)
└── k3s worker (node-type=bare-metal, node-role=customer)
    └── Independent hardware, local ext4 storage
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
- **Workers:** nuc (192.168.2.102), MicroVMs (10.100.0.11-13)
- **Networking:** Flannel VXLAN
- **GitOps:** Flux CD (repo: `flux-system`)
- **Storage:** OpenEBS ZFS (local), democratic-csi (NFS over SSH)

```
mothership (control-plane)
├── k3s server, ZFS pools, NFS server for democratic-csi
│
├── nuc (bare-metal worker, 192.168.2.102)
│   ├── Independent hardware, survives mothership downtime
│   ├── Local ext4 disk (hostPath for customer workloads)
│   └── NFS client for democratic-csi shared storage
│
└── MicroVMs on mothership (cloud-hypervisor)
    ├── k3s-worker-1 (10.100.0.11)
    ├── k3s-worker-2 (10.100.0.12)
    └── k3s-worker-3 (10.100.0.13)
```

### Node Labels

Labels are set via `--node-label` in each agent's k3s config. Use these for `nodeSelector` in deployments.

| Label | Values | Purpose |
|-------|--------|---------|
| `k3s.io/role` | `worker` | All worker nodes (nuc + microvms) |
| `node-type` | `bare-metal`, `microvm` | Broad scheduling by hardware type |
| `node-id` | `nuc`, `worker-1`, `worker-2`, `worker-3` | Target a specific node |
| `node-role` | `customer` | Customer-facing workloads (nuc only) |

**Label map:**

| Node | `node-type` | `node-id` | `node-role` |
|------|-------------|-----------|-------------|
| mothership | — | — | — |
| nuc | `bare-metal` | `nuc` | `customer` |
| k3s-worker-1 | `microvm` | `worker-1` | — |
| k3s-worker-2 | `microvm` | `worker-2` | — |
| k3s-worker-3 | `microvm` | `worker-3` | — |

**Scheduling examples:**
```yaml
# All workers
nodeSelector:
  k3s.io/role: worker

# Only microvms (e.g. observability, internal workloads)
nodeSelector:
  node-type: microvm

# Only physical hardware
nodeSelector:
  node-type: bare-metal

# Specific node
nodeSelector:
  node-id: worker-2

# Customer workloads (pinned to nuc, survives mothership reboot)
nodeSelector:
  node-role: customer
```

### Storage Classes

| Class | Provisioner | Backend | Nodes |
|-------|-------------|---------|-------|
| `zfs-fast` (default) | openebs | `fastPool/k3s` on mothership | mothership only |
| `zfs-slow` | openebs | `slowPool/k3s` on mothership | mothership only |
| `nfs-fast` | democratic-csi | ZFS over NFS from mothership | all nodes |
| `nfs-slow` | democratic-csi | ZFS over NFS from mothership | all nodes |

For workloads that must survive mothership downtime (e.g. customer sites on nuc), use `hostPath` volumes instead of CSI storage classes.

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
