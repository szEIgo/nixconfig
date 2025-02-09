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


        #printing.enable = true;
         # pipewire = {
         #   enable = true;
         #   pulse.enable = true;
         # };
    };
}
