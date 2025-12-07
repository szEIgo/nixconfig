{ config, lib, pkgs, ... }: {
  services = {
    logind = {
      settings.Login = {
        HandlePowerKey = "ignore";
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        IdleAction = "ignore";
      };
    };
    displayManager = {
      sddm.enable = true;
      sddm.wayland.enable = true;
    };
  };
}

