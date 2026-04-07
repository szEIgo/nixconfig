# eGPU configuration for Lenovo Thunderbolt eGPU dock (GTX 1050 Mobile)
#
# Strategy: Intel UHD 620 remains the primary display adapter so the desktop
# session survives Thunderbolt hot-unplug. The NVIDIA GPU is available as a
# PRIME render-offload device when the dock is connected.
#
# Run apps on the eGPU with:
#   nvidia-offload <command>       (wrapper defined below)
#   __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia <command>
{ config, lib, pkgs, ... }: {

  # Legacy 580.xx driver requires explicit license acceptance
  nixpkgs.config.nvidia.acceptLicense = true;

  # --- Thunderbolt ---
  services.hardware.bolt.enable = true;

  # --- Kernel modules ---
  # Do NOT load nvidia in initrd — it must be optional for hot-unplug
  boot.kernelModules = [ "thunderbolt" ];
  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.kernelParams = [
    "modprobe.blacklist=nouveau"
  ];

  # --- NVIDIA driver (proprietary, closed-source for Pascal support) ---
  services.xserver.videoDrivers = [ "modesetting" "nvidia" ];

  hardware.nvidia = {
    # GTX 1050 (GP107/Pascal) requires the 580.xx legacy branch —
    # the 590.xx+ driver dropped support for this GPU.
    package = config.boot.kernelPackages.nvidiaPackages.dc_580;
    # GP107 (Pascal) is NOT supported by the open kernel module
    open = false;
    modesetting.enable = true;

    # PRIME: Intel is primary, NVIDIA is render offload
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;  # provides `nvidia-offload` wrapper
      };
      # PCI bus IDs (from lspci: 00:02.0 and 09:00.0)
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:9:0:0";
    };

    # Basic power management for suspend/resume — finegrained (RTD3) requires
    # Turing or newer, so not available for Pascal GP107.
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    # Legacy 580.xx driver may not ship nvidia-settings
    nvidiaSettings = false;
  };

  # 32-bit support for games/compatibility
  hardware.graphics.enable32Bit = true;

  # --- udev rule: gracefully handle Thunderbolt eGPU removal ---
  services.udev.extraRules = ''
    # When the NVIDIA eGPU is removed, trigger a clean device removal
    ACTION=="remove", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", RUN+="${pkgs.bash}/bin/bash -c 'echo 1 > /sys/bus/pci/rescan'"
  '';

  # --- Helpful packages ---
  environment.systemPackages = with pkgs; [
    pciutils          # lspci for debugging
    nvtopPackages.full  # GPU monitoring
  ];
}
