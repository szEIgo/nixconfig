.PHONY: switch build test update gc bootstrap cleanup secrets-edit secrets-updatekeys gpu-reset usb-attach k3s-init k3s-wipe k3s-status k3s-flux-init k3s-flux-bootstrap k3s-flux-status k3s-flux-reconcile vm-fix-efi vnc mount help

# Help
help:
	@./scripts/help.sh

# NixOS
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

# Bootstrap
bootstrap:
	@./scripts/bootstrap/decrypt-keys.sh

cleanup:
	@./scripts/bootstrap/cleanup-master-key.sh

# Secrets
secrets-edit:
	@./scripts/secrets/edit.sh

secrets-updatekeys:
	@./scripts/secrets/updatekeys.sh

# Hardware
gpu-reset:
	@./scripts/hardware/amd-gpu-reset.sh

usb-attach:
	@./scripts/hardware/attach-usb-to-vm.sh $(VM)

# K3s
k3s-init:
	@./scripts/k3s/init.sh

k3s-wipe:
	@./scripts/k3s/wipe.sh $(ARGS)

k3s-status:
	@./scripts/k3s/status.sh

# K3s Flux
k3s-flux-init:
	@./scripts/k3s/flux-init.sh

k3s-flux-bootstrap:
	@./scripts/k3s/flux-bootstrap.sh

k3s-flux-status:
	@./scripts/k3s/flux-status.sh

k3s-flux-reconcile:
	@./scripts/k3s/flux-reconcile.sh $(TARGET)

# VM
vm-fix-efi:
	@./scripts/vm/fix-efi.sh $(VM)

vnc:
	@./scripts/vm/start-vnc.sh

# Storage
mount:
	@./scripts/storage/mount-pools.sh


