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
    kdePackages.bluedevil
    bluez
    bluez-tools
    wireplumber

    # KDE Control Station dependencies
    kdePackages.plasma-nm          # org.kde.plasma.networkmanagement
    kdePackages.plasma-workspace   # session actions

    # Disk monitoring
    quota                          # Disk Quota widget
  ];
}

