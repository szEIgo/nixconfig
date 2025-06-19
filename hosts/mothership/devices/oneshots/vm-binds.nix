# vm-bind.nix (or split into multiple files if you prefer)

{ config, pkgs, lib, ... }:

let
  # Grouped devices
  amdPciDevices = [
    {
      pci = "0000:0d:00.0";
      driver = "amdgpu";
    }
    {
      pci = "0000:0d:00.1";
      driver = "snd_hda_intel";
    }
  ];

  nvidiaPciDevices = [
    {
      pci = "0000:0e:00.0";
      driver = "nvidia";
    }
    {
      pci = "0000:0e:00.1";
      driver = "snd_hda_intel";
    }
    {
      pci = "0000:0e:00.2";
      driver = "xhci_hcd";
    }
    {
      pci = "0000:0e:00.3";
      driver = "i2c_nvidia_gpu";
    }
  ];

  # Optional USB XML device list
  usbXmlDevices =
    [ "keyboard.xml" "mouse.xml" "headset1.xml" "headset2.xml" "speakers.xml" ];

  attachDevicesScript = vm:
    builtins.concatStringsSep "\n"
    (map (f: "virsh attach-device ${vm} --file /home/joni/vm/${f} --current")
      usbXmlDevices);
  detachDevicesScript = vm:
    builtins.concatStringsSep "\n"
    (map (f: "virsh detach-device ${vm} --file /home/joni/vm/${f} --live")
      usbXmlDevices);

  rebindScript = driver: devices:
    builtins.concatStringsSep "\n" (map (d: ''
      echo ${driver} > /sys/bus/pci/devices/${d.pci}/driver_override || true
      echo ${d.pci} > /sys/bus/pci/devices/${d.pci}/driver/unbind || true
      echo ${d.pci} > /sys/bus/pci/drivers/${driver}/bind || true
    '') devices);

in {
  systemd.services.vm-attach-usb-amd = {
    description = "Attach USB devices to AMD VM";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "attach-usb-amd" ''
        ${attachDevicesScript "win10-AMD"}
      '';
    };
  };

  systemd.services.vm-detach-usb-2070 = {
    description = "Detach USB devices from 2070 VM";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "detach-usb-2070" ''
        ${detachDevicesScript "win10-2070"}
      '';
    };
  };

  systemd.services.bind-vfio-amd = {
    description = "Bind AMD GPU to vfio-pci";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "bind-vfio-amd" ''
        set -eux
        ${rebindScript "vfio-pci" amdPciDevices}
      '';
    };
  };

  systemd.services.rebind-host-nvidia = {
    description = "Rebind NVIDIA GPU/audio back to host drivers";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "rebind-host-nvidia" ''
        set -eux
        ${rebindScript "nvidia" nvidiaPciDevices}
      '';
    };
  };
}
