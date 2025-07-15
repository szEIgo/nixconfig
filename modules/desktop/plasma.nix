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
    kdePackages.bluedevil # ✅ Corrected for Qt6 / Plasma 6
    bluez
    bluez-tools
    wireplumber
  ];
}

