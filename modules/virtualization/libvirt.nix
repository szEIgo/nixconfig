{ config, pkgs, ... }:

let
  libvirt-hook-script = pkgs.writeShellScriptBin "kvm-amd-reset-hook" ''
    #!${pkgs.bash}/bin/bash
    set -x # This line prints every command to the log, which is great for debugging.

    VM_NAME="$1"
    OPERATION="$2"
    LOG_FILE="/tmp/vfio-hook-debug.log" # Using a new log file

    # --- SCRIPT CONFIGURATION ---
    TARGET_VM="win11-amd"
    GPU_ID="0000:0d:00.0"
    AUDIO_ID="0000:0d:00.1"
    # --- END CONFIGURATION ---

    echo "---" >> "$LOG_FILE"
    echo "$(date): Hook triggered for VM: $VM_NAME, Operation: $OPERATION" >> "$LOG_FILE"

    if [ "$VM_NAME" = "$TARGET_VM" ]; then
      if [ "$OPERATION" = "prepare" ] || [ "$OPERATION" = "release" ]; then
        
        # Unbind GPU from the vfio-pci driver.
        # The '2>/dev/null || true' part ignores errors if the device is already unbound,
        # allowing the script to continue to the crucial reset step.
        echo "Attempting to unbind devices from vfio-pci..." >> "$LOG_FILE"
        echo "$GPU_ID" > "/sys/bus/pci/drivers/vfio-pci/unbind" 2>/dev/null || true
        echo "$AUDIO_ID" > "/sys/bus/pci/drivers/vfio-pci/unbind" 2>/dev/null || true

        # Wait a moment for the unbind to take effect.
        sleep 1

        # Reset the GPU using vendor-reset.
        echo "Attempting to reset the GPU..." >> "$LOG_FILE"
        echo "1" > "/sys/bus/pci/devices/$GPU_ID/reset"
        echo "1" > "/sys/bus/pci/devices/$AUDIO_ID/reset"
        
        # Wait a moment for the reset to complete.
        sleep 1

        # Rebind GPU back to the vfio-pci driver.
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

    # This is the corrected hooks section, matching the official NixOS documentation.
    # It defines a SET of hooks, where the key is the script name and the value is the path.
    hooks.qemu = {
      "amd-gpu-reset" = "${libvirt-hook-script}/bin/kvm-amd-reset-hook";
    };

    # Your existing QEMU and OVMF configuration remains untouched.
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;

      ovmf = {
        enable = true;
        packages = [
          (pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd
        ];
      };
    };
  };

  systemd.tmpfiles.rules = [ "z /dev/zd* 0660 root libvirtd -" ];

  systemd.services.libvirtd.serviceConfig = {
    SupplementaryGroups = [ "libvirtd" ];
  };
}
