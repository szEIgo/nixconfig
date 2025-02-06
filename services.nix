{ config, lib, pkgs, ... }:
{

    services = {
        logind = {
          extraConfig = ''
            HandlePowerKey=ignore
            HandleLidSwitch=ignore
            HandleLidSwitchExternalPower=ignore
            IdleAction=ignore
          '';
        };
        xserver = {
            enable = true;
            videoDrivers = ["amdgpu"];
            deviceSection = ''
                  Option "TearFree" "true"
                '';
            #displayManager.sddm.autoSuspend = false;
        };
        displayManager = {
            sddm.enable = true;
            sddm.wayland.enable = true;
            sddm.wayland.compositor = "kwin";

        };
        desktopManager = {
            plasma6.enable = true;
            plasma6.enableQt5Integration = false;
        };
        #printing.enable = true;
         # pipewire = {
         #   enable = true;
         #   pulse.enable = true;
         # };
    };
}