{ config, pkgs, ... }:

let
  libvirt-hook-script = pkgs.writeShellScriptBin "kvm-amd-reset-hook" ''
    #!${pkgs.bash}/bin/bash
    set -x

    VM_NAME="$1"
    OPERATION="$2"
    LOG_FILE="/tmp/vfio-hook-debug.log"

    TARGET_VM="win11-amd"
    GPU_ID="0000:0d:00.0"
    AUDIO_ID="0000:0d:00.1"

    echo "---" >> "$LOG_FILE"
    echo "$(date): Hook triggered for VM: $VM_NAME, Operation: $OPERATION" >> "$LOG_FILE"

    if [ "$VM_NAME" = "$TARGET_VM" ]; then
      if [ "$OPERATION" = "prepare" ] || [ "$OPERATION" = "release" ]; then

        echo "Attempting to unbind devices from vfio-pci..." >> "$LOG_FILE"
        echo "$GPU_ID" > "/sys/bus/pci/drivers/vfio-pci/unbind" 2>/dev/null || true
        echo "$AUDIO_ID" > "/sys/bus/pci/drivers/vfio-pci/unbind" 2>/dev/null || true

        sleep 1

        echo "Attempting to reset the GPU..." >> "$LOG_FILE"
        echo "1" > "/sys/bus/pci/devices/$GPU_ID/reset"
        echo "1" > "/sys/bus/pci/devices/$AUDIO_ID/reset"

        sleep 1

        echo "Attempting to rebind devices to vfio-pci..." >> "$LOG_FILE"
        echo "$GPU_ID" > "/sys/bus/pci/drivers/vfio-pci/bind" 2>/dev/null || true
        echo "$AUDIO_ID" > "/sys/bus/pci/drivers/vfio-pci/bind" 2>/dev/null || true

        echo "Hook finished." >> "$LOG_FILE"
      fi
    fi
  '';
in {
  users.groups = { libvirtd = { }; };

  virtualisation.libvirtd = {
    enable = true;

    hooks.qemu = {
      "amd-gpu-reset" = "${libvirt-hook-script}/bin/kvm-amd-reset-hook";
    };

    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  systemd.tmpfiles.rules = [ "z /dev/zd* 0660 root libvirtd -" ];

  systemd.services.libvirtd.serviceConfig = {
    SupplementaryGroups = [ "libvirtd" ];
  };
}

