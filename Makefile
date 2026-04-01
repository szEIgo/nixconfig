.PHONY: help deploy deploy-all deploy-new fleet-listen worker-iso flash-worker-iso switch switch-interactive build test update gc \
        bootstrap add-host-keys cleanup secrets-edit secrets-updatekeys secrets-list \
        gpu-reset usb-attach vm-list vm-start vm-stop vm-console vm-fix-efi vnc \
        zfs-status zfs-scrub zfs-snapshot mount \
        k3s-status k3s-wipe k3s-flux-init k3s-flux-bootstrap k3s-flux-status k3s-flux-reconcile \
        wg-connect wg-disconnect wg-status

# =============================================================================
# HELP
# =============================================================================
help:
	@./scripts/help.sh

# =============================================================================
# DEPLOYMENT (deploy-rs with automatic rollback)
# =============================================================================
deploy:
	@if [ -z "$(HOST)" ]; then echo "Usage: make deploy HOST=<node>"; exit 1; fi
	nix run github:serokell/deploy-rs -- .#$(HOST)

deploy-all:
	nix run github:serokell/deploy-rs -- .

# =============================================================================
# INSTALL (fresh node provisioning via nixos-anywhere)
# =============================================================================
deploy-new:
	@./scripts/bootstrap/deploy-worker.sh $(HOST) $(IP)

fleet-listen:
	@./scripts/bootstrap/fleet-listen.sh

worker-iso:
	nix build .#images.worker-iso
	@echo "ISO: $$(ls result/iso/*.iso)"

flash-worker-iso:
	@./scripts/bootstrap/flash-worker-iso.sh

# =============================================================================
# NIXOS (local rebuild)
# =============================================================================
switch:
	@./scripts/nixos/switch.sh $(HOST) $(SPEC)

switch-interactive:
	@./scripts/nixos/switch.sh $(HOST) interactive

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

add-host-keys:
	@./scripts/bootstrap/add-host-keys.sh $(HOST) $(IP)

cleanup:
	@./scripts/bootstrap/cleanup-master-key.sh

secrets-edit:
	@./scripts/secrets/edit.sh

secrets-updatekeys:
	@./scripts/secrets/updatekeys.sh

secrets-list:
	@./scripts/secrets/list.sh

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
k3s-status:
	@./scripts/k3s/status.sh

k3s-wipe:
	@./scripts/k3s/wipe.sh $(ARGS)

k3s-flux-init:
	@./scripts/k3s/flux-init.sh

k3s-flux-bootstrap:
	@./scripts/k3s/flux-bootstrap.sh

k3s-flux-status:
	@./scripts/k3s/flux-status.sh

k3s-flux-reconcile:
	@./scripts/k3s/flux-reconcile.sh $(TARGET)

# =============================================================================
# WIREGUARD VPN
# =============================================================================
wg-connect:
	@./scripts/wireguard/connect.sh

wg-disconnect:
	@./scripts/wireguard/disconnect.sh

wg-status:
	@./scripts/wireguard/status.sh
