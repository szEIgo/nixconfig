{ config, lib, pkgs, ... }: {
  services = {
    desktopManager.plasma6.enable = true;

    printing.enable = true;

    pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = { General = { Enable = "Source,Sink,Media,Socket"; }; };
  };

  environment.systemPackages = with pkgs; [
    bluedevil
    bluez
    bluez-tools
    wireplumber
  ];
}
