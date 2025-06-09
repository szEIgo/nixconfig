{
  config,
  lib,
  pkgs,
  ...
}: {
  services = {
    logind = {
      extraConfig = ''
        HandlePowerKey=ignore
        HandleLidSwitch=ignore
        HandleLidSwitchExternalPower=ignore
        IdleAction=ignore
      '';
    };

    displayManager = {
      sddm.enable = true;
      sddm.wayland.enable = true;
    };
  };
}
