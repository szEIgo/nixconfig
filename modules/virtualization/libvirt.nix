{ config, pkgs, ... }:

let
  # This correctly defines the single, smart hook script declaratively.
  libvirt-hook-script = pkgs.writeShellScriptBin "kvm-amd-reset-hook" ''
    #!${pkgs.bash}/bin/bash

    VM_NAME="$1"
    OPERATION="$2"

    TARGET_VM="win11-amd"

    # !!! YOU MUST REPLACE THESE WITH YOUR ACTUAL PCI ADDRESSES !!!
    GPU_ID="0000:0d:00.0"
    AUDIO_ID="0000:0d:00.1"

    if [ "$VM_NAME" = "$TARGET_VM" ]; then
      if [ "$OPERATION" = "prepare" ] || [ "$OPERATION" = "release" ]; then
        echo "$GPU_ID" > "/sys/bus/pci/drivers/vfio-pci/unbind"
        echo "$AUDIO_ID" > "/sys/bus/pci/drivers/vfio-pci/unbind"
        echo "1" > "/sys/bus/pci/devices/$GPU_ID/reset"
        echo "1" > "/sys/bus/pci/devices/$AUDIO_ID/reset"
        sleep 1
        echo "$GPU_ID" > "/sys/bus/pci/drivers/vfio-pci/bind"
        echo "$AUDIO_ID" > "/sys/bus/pci/drivers/vfio-pci/bind"
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
