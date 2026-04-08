# eGPU configuration for Lenovo Thunderbolt eGPU dock (GTX 1050 Mobile)
#
# Strategy: Intel UHD 620 remains the primary display adapter so the desktop
# session survives Thunderbolt hot-unplug. The NVIDIA GPU is available as a
# PRIME render-offload device when the dock is connected.
#
# Run apps on the eGPU with:
#   nvidia-offload <command>
#   __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia <command>
#
# Driver note: the 470.xx legacy driver is used instead of 580.xx because
# 580.xx causes the Thunderbolt PCIe link to downgrade from 8 GT/s to 2.5 GT/s.
{ config, lib, pkgs, ... }: {

  # Legacy driver requires explicit license acceptance
  nixpkgs.config.nvidia.acceptLicense = true;

  # --- Thunderbolt ---
  services.hardware.bolt.enable = true;

  # --- Kernel modules ---
  boot.kernelModules = [ "thunderbolt" ];
  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.kernelParams = [ "modprobe.blacklist=nouveau" ];

  # --- NVIDIA driver ---
  services.xserver.videoDrivers = [ "modesetting" "nvidia" ];

  hardware.nvidia = {
    # 470.xx maintains PCIe Gen 3 (8 GT/s) over Thunderbolt.
    # 580.xx and 590.xx both downgrade the link to 2.5 GT/s.
    package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
    open = false;
    modesetting.enable = true;

    # PRIME: Intel is primary, NVIDIA is render offload
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:9:0:0";
    };

    powerManagement.enable = true;
    powerManagement.finegrained = false;
    nvidiaSettings = false;
  };

  hardware.graphics.enable32Bit = true;

  # Force kwin to composite on Intel (card1) and use NVIDIA (card0) for
  # display output only. First device = render GPU, second = output GPU.
  environment.sessionVariables.KWIN_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";

  # --- Prevent TLP from power-managing eGPU PCIe devices ---
  services.tlp.settings = {
    RUNTIME_PM_DENYLIST = "09:00.0 09:00.1";
  };

  # --- Boot-time PCIe link fix: unload driver, bus reset, reload at Gen 3 ---
  # The Thunderbolt link often trains at Gen 1 (2.5 GT/s) if the nvidia driver
  # loads before the link fully negotiates. This service safely resets the link
  # before the display manager starts.
  systemd.services.egpu-pcie-retrain = {
    description = "Retrain eGPU PCIe link to Gen 3 speed";
    after = [ "bolt.service" ];
    wants = [ "bolt.service" ];
    before = [ "display-manager.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.pciutils pkgs.kmod ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = let
        script = pkgs.writeShellScript "egpu-boot-retrain" ''
          set -euo pipefail

          # Wait for GPU to appear on PCI bus
          for i in $(seq 1 30); do
            if [ -e /sys/bus/pci/devices/0000:09:00.0 ]; then break; fi
            echo "Waiting for eGPU... ($i/30)"
            sleep 2
          done

          if [ ! -e /sys/bus/pci/devices/0000:09:00.0 ]; then
            echo "eGPU not found, skipping"
            exit 0
          fi

          speed=$(cat /sys/bus/pci/devices/0000:09:00.0/current_link_speed 2>/dev/null || echo 'unknown')
          echo "Current link speed: $speed"

          if echo "$speed" | grep -q "8.0"; then
            echo "Already at Gen 3, done"
            exit 0
          fi

          echo "Link at $speed — performing bus reset..."

          # Unload nvidia driver
          echo 0000:09:00.0 > /sys/bus/pci/drivers/nvidia/unbind 2>/dev/null || true
          modprobe -r nvidia_uvm nvidia_drm nvidia_modeset nvidia 2>/dev/null || true
          sleep 1

          # Remove GPU from bus
          echo 1 > /sys/bus/pci/devices/0000:09:00.0/remove 2>/dev/null || true
          echo 1 > /sys/bus/pci/devices/0000:09:00.1/remove 2>/dev/null || true
          sleep 1

          # Set target speed to 8GT/s on bridges
          for dev in 05:01.0 07:00.0 08:01.0; do
            current=$(setpci -s "$dev" CAP_EXP+30.W 2>/dev/null || echo "0000")
            new=$(printf "%04x" $(( (0x$current & 0xFFF0) | 0x0003 )))
            setpci -s "$dev" CAP_EXP+30.W="0x$new" 2>/dev/null || true
          done

          # Secondary bus reset
          current=$(setpci -s 05:01.0 BRIDGE_CONTROL 2>/dev/null || echo "00")
          new=$(printf "%02x" $(( 0x$current | 0x40 )))
          setpci -s 05:01.0 BRIDGE_CONTROL="0x$new" 2>/dev/null || true
          sleep 0.5
          setpci -s 05:01.0 BRIDGE_CONTROL="0x$current" 2>/dev/null || true
          sleep 2

          # Rescan and reload
          echo 1 > /sys/bus/pci/rescan
          sleep 3
          modprobe nvidia
          modprobe nvidia_modeset
          modprobe nvidia_drm
          modprobe nvidia_uvm 2>/dev/null || true
          sleep 2

          echo "Final: $(cat /sys/bus/pci/devices/0000:09:00.0/current_link_speed 2>/dev/null || echo 'unknown')"
        '';
      in "${script}";
    };
  };

  # --- udev rule: gracefully handle Thunderbolt eGPU removal ---
  services.udev.extraRules = ''
    ACTION=="remove", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", RUN+="${pkgs.bash}/bin/bash -c 'echo 1 > /sys/bus/pci/rescan'"
  '';

  # --- Helpful packages ---
  environment.systemPackages = with pkgs; [
    pciutils
    nvtopPackages.full
    mesa-demos
  ];
}
