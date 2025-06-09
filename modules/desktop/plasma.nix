{
  config,
  lib,
  pkgs,
  ...
}: {
  services = {
    desktopManager = {
      plasma6.enable = true;
      #plasma6.enableQt5Integration = true;
    };
    printing.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };
}
