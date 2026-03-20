.PHONY: help switch build test update gc bootstrap cleanup secrets-edit secrets-updatekeys \
        gpu-reset usb-attach vm-list vm-start vm-stop vm-console vm-fix-efi vnc \
        zfs-status zfs-scrub zfs-snapshot mount \
        k3s-init k3s-wipe k3s-status k3s-flux-init k3s-flux-bootstrap k3s-flux-status k3s-flux-reconcile \
        microvm-list microvm-status microvm-start microvm-stop microvm-restart microvm-ssh \
        microvm-init-zfs microvm-destroy-zfs microvm-resize

# =============================================================================
# HELP
# =============================================================================
help:
	@./scripts/help.sh

# =============================================================================
# NIXOS
# =============================================================================
switch:
	@./scripts/nixos/switch.sh $(HOST)

build:
	@./scripts/nixos/build.sh $(HOST)

test:
	@./scripts/nixos/test.sh $(HOST)

update:
	@./scripts/nixos/update.sh $(HOST)

gc:
	@./scripts/nixos/gc.sh $(DAYS)

# =============================================================================
# BOOTSTRAP & SECRETS
# =============================================================================
bootstrap:
	@./scripts/bootstrap/decrypt-keys.sh

cleanup:
	@./scripts/bootstrap/cleanup-master-key.sh

secrets-edit:
	@./scripts/secrets/edit.sh

secrets-updatekeys:
	@./scripts/secrets/updatekeys.sh

# =============================================================================
# STORAGE (ZFS)
# =============================================================================
mount:
	@./scripts/storage/mount-pools.sh

zfs-status:
	@./scripts/storage/zfs-status.sh

zfs-scrub:
	@./scripts/storage/zfs-scrub.sh

zfs-snapshot:
	@./scripts/storage/zfs-snapshot.sh $(DATASET)

# =============================================================================
# VIRTUAL MACHINES (LIBVIRT)
# =============================================================================
vm-list:
	@./scripts/vm/list.sh

vm-start:
	@./scripts/vm/start.sh $(VM)

vm-stop:
	@./scripts/vm/stop.sh $(VM)

vm-console:
	@./scripts/vm/console.sh $(VM)

vm-fix-efi:
	@./scripts/vm/fix-efi.sh $(VM)

vnc:
	@./scripts/vm/start-vnc.sh

# =============================================================================
# HARDWARE
# =============================================================================
gpu-reset:
	@./scripts/hardware/amd-gpu-reset.sh

usb-attach:
	@./scripts/hardware/attach-usb-to-vm.sh $(VM)

# =============================================================================
# KUBERNETES (K3S)
# =============================================================================
k3s-init:
	@./scripts/k3s/init.sh

k3s-wipe:
	@./scripts/k3s/wipe.sh $(ARGS)

k3s-status:
	@./scripts/k3s/status.sh

k3s-flux-init:
	@./scripts/k3s/flux-init.sh

k3s-flux-bootstrap:
	@./scripts/k3s/flux-bootstrap.sh

k3s-flux-status:
	@./scripts/k3s/flux-status.sh

k3s-flux-reconcile:
	@./scripts/k3s/flux-reconcile.sh $(TARGET)

# =============================================================================
# MICROVMS
# =============================================================================
microvm-list:
	@./scripts/microvm/list.sh

microvm-status:
	@./scripts/microvm/status.sh $(VM)

microvm-start:
	@./scripts/microvm/start.sh $(VM)

microvm-stop:
	@./scripts/microvm/stop.sh $(VM)

microvm-restart:
	@./scripts/microvm/restart.sh $(VM)

microvm-ssh:
	@./scripts/microvm/ssh.sh $(VM)

microvm-init-zfs:
	@./scripts/microvm/init-zfs.sh

microvm-destroy-zfs:
	@./scripts/microvm/destroy-zfs.sh

microvm-resize:
	@./scripts/microvm/resize-zfs.sh $(ID) $(SIZE)
