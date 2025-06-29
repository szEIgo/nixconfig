{ config, lib, pkgs, ... }: {

  environment.systemPackages = with pkgs; [
    xorg.xorgserver
    xorg.xf86videoDummy
  ];

  # Optional: script to launch dummy X server manually or via systemd
  systemd.services.dummy-xserver = {
    description = "Dummy X Server on :1 for virtual display (Sunshine)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart =
        "${pkgs.xorg.xorgserver}/bin/X :1 -config /etc/dummy-xorg.conf -noreset";
      StandardOutput = "journal";
      Restart = "on-failure";
    };
  };

  # Write dummy X config to /etc/dummy-xorg.conf
  environment.etc."dummy-xorg.conf".text = ''
    Section "Device"
        Identifier "DummyDevice"
        Driver "dummy"
        VideoRam 256000
    EndSection

    Section "Monitor"
        Identifier "DummyMonitor"
        HorizSync 28.0-80.0
        VertRefresh 48.0-75.0
        Modeline "1920x1080" 148.50 1920 2008 2052 2200 1080 1084 1089 1125 +hsync +vsync
    EndSection

    Section "Screen"
        Identifier "DummyScreen"
        Device "DummyDevice"
        Monitor "DummyMonitor"
        DefaultDepth 24
        SubSection "Display"
            Depth 24
            Modes "1920x1080"
        EndSubSection
    EndSection

    Section "ServerLayout"
        Identifier "DummyLayout"
        Screen "DummyScreen"
    EndSection
  '';
}
