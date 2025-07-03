{ config, lib, pkgs, ... }: {

  environment.systemPackages = with pkgs; [ xorg.xf86videodummy ];

  # Optional: script to launch dummy X server manually or via systemd
  systemd.services.dummy-xserver = {
    description = "Dummy X Server on :1 for virtual display (Sunshine)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart =
        "${pkgs.xorg.xorgserver}/bin/X :1 -config /etc/dummy-xorg.conf -noreset";
      Restart = "on-failure";
      StandardOutput = "journal";
    };
  };

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
        Modeline "2048x1332" 230.00  2048 2184 2400 2752  1332 1335 1345 1393 -hsync +vsync
    EndSection

    Section "Screen"
        Identifier "DummyScreen"
        Device "DummyDevice"
        Monitor "DummyMonitor"
        DefaultDepth 24
        SubSection "Display"
            Depth 24
            Modes "2048x1332"
        EndSubSection
    EndSection

    Section "ServerLayout"
        Identifier "DummyLayout"
        Screen "DummyScreen"
    EndSection
  '';

}
