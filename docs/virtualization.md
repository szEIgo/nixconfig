# Virtualization

VMs and Kubernetes on mothership.

**Navigation:** [README](../README.md) | [Usage](usage.md) | [ZFS](zfs.md) | [Structure](structure.md)

---

## Architecture Overview

```
mothership (control-plane, 32c/32GB)
├── libvirt (KVM/QEMU)
│   ├── win11-nvidia     # Windows 11 + NVIDIA GPU
│   ├── win11-amd        # Windows 11 + AMD GPU
│   ├── win11-goldenImage
│   └── archlinux
│
├── k3s server (HA, embedded etcd, --cluster-init)
│   └── Carrier and interceptor nodes join via LAN
│
└── Podman (Docker-compatible containers)
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
make vm-list
make vm-start VM=win11-nvidia
make vm-stop VM=win11-nvidia
make vm-console VM=win11-nvidia
virsh destroy win11-nvidia       # Force stop
```

### GPU Passthrough

VMs use VFIO for GPU passthrough. Kernel params in `configuration.nix` bind GPUs to vfio-pci at boot.

```bash
make gpu-reset                   # Reset AMD GPU after VM shutdown
make usb-attach VM=win11-nvidia  # Attach USB to running VM
```

### Specialisations

Boot into different GPU configurations:

| Specialisation | Description |
|---------------|-------------|
| `dualGpu` | Both GPUs available to host |
| `amd` | AMD GPU to host, NVIDIA to VFIO |
| `nvidia` | NVIDIA to host, AMD to VFIO |

Select at boot via systemd-boot menu.

---

## Kubernetes (k3s)

### Architecture

3-node HA control plane with embedded etcd. Fleet naming: StarCraft Protoss theme.

```
mothership (control-plane, --cluster-init)
├── carrier-tc1  (control-plane, 192.168.2.192)
├── carrier-tc2  (control-plane, 192.168.2.250)
├── interceptor-nuc1 (worker, 192.168.2.102)
├── interceptor-tc1  (worker, 192.168.2.238)
└── interceptor-tc2  (worker, 192.168.2.147)
```

- **Networking:** Flannel VXLAN
- **GitOps:** Flux CD
- **Storage:** OpenEBS ZFS (local on mothership), democratic-csi (NFS)
- **Deployment:** deploy-rs with automatic rollback

### Node Labels

| Label | Values | Purpose |
|-------|--------|---------|
| `node-id` | `mothership`, `carrier-tc1`, etc. | Target a specific node |
| `node.kubernetes.io/size` | `small`, `medium`, `large` | Schedule by resource tier |

```yaml
# Target medium or large nodes
nodeSelector:
  node.kubernetes.io/size: medium

# Target a specific node
nodeSelector:
  node-id: carrier-tc1
```

### Storage Classes

| Class | Provisioner | Backend | Nodes |
|-------|-------------|---------|-------|
| `zfs-fast` (default) | openebs | `fastPool/k3s` on mothership | mothership only |
| `zfs-slow` | openebs | `slowPool/k3s` on mothership | mothership only |
| `nfs-fast` | democratic-csi | ZFS over NFS from mothership | all nodes |
| `nfs-slow` | democratic-csi | ZFS over NFS from mothership | all nodes |

### Fleet Deployment

```bash
# Deploy config to a single node (with automatic rollback)
make deploy HOST=carrier-tc1

# Deploy to all fleet nodes
make deploy-all

# Fresh install a new node
make deploy-new HOST=interceptor-tc2 IP=192.168.2.147
```

### Status & Flux CD

```bash
make k3s-status
make k3s-flux-bootstrap
make k3s-flux-status
make k3s-flux-reconcile
```

### Boot Resilience

Fleet nodes are configured for automatic recovery on reboot:
- `sops-nix.service` decrypts the k3s token before k3s starts
- `k3s-role-guard` service detects role changes (agent/server) and cleans stale state
- k3s has `Restart=always` with 5s backoff for transient failures
- ssh-agent runs as a systemd user service (no GUI required)

---

## MicroVMs (disabled)

Lightweight k3s worker VMs using cloud-hypervisor. Currently disabled in favor
of bare-metal fleet nodes. The module is complete and can be re-enabled by
uncommenting one line in `hosts/mothership/configuration.nix`.

Config: `modules/virtualization/microvm/`

---

## Podman

Container runtime (Docker-compatible).

```bash
podman run -it alpine
podman ps -a
podman-compose up -d
```

Configuration in `modules/virtualization/podman.nix`.

---

## Files Reference

| Path | Purpose |
|------|---------|
| `modules/virtualization/k3s.nix` | K3s control plane (mothership) |
| `modules/virtualization/libvirt.nix` | KVM/QEMU, VFIO hooks, polkit |
| `modules/virtualization/podman.nix` | Container runtime |
| `modules/virtualization/vms/` | NixVirt VM definitions + XML |
| `modules/virtualization/microvm/` | MicroVM host + guest config (disabled) |
| `hosts/worker/` | Shared fleet node config |

---

**See also:** [ZFS](zfs.md) | [Usage](usage.md) | [Structure](structure.md)
