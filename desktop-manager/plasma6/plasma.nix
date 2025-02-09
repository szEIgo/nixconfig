{ config, lib, pkgs, ... }:
{

    services = {

        displayManager = {
            sddm.enable = true;
            sddm.wayland.enable = true;
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
