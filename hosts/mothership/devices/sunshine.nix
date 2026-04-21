{ config, pkgs, lib, ... }:

let
  username = "joni";
  uid = 1000;
  kscreen = "${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor";

  # DP-1 = main "BIG" ultrawide (5120x1440@120Hz)
  # DP-2 = dummy plug for headless streaming
  mainDisplay = "DP-1";
  dummyDisplay = "DP-2";
  # Moonlight "native" resolution for Xiaomi 15 Ultra
  streamResolution = "2273x1080@60";

  # Script to wake display from DPMS sleep by sending a fake keypress.
  # Needed for headless/dummy-plug streaming: KDE puts the display to
  # DPMS off when idle, and Sunshine's KMS capture can't see a sleeping screen.
  wakeDisplay = pkgs.writeShellScript "wake-display" ''
    ${pkgs.perl}/bin/perl -e '
      use POSIX;
      sub make_event {
        my ($type, $code, $value) = @_;
        return pack("qqSSl", time(), 0, $type, $code, $value);
      }
      # Find a keyboard event device
      my $dev;
      open(my $fh, "<", "/proc/bus/input/devices") or exit 1;
      while (<$fh>) {
        if (/Handlers=.*?(event\d+)/ && $prev =~ /keyboard/i) {
          $dev = "/dev/input/$1"; last;
        }
        $prev = $_;
      }
      close($fh);
      exit 1 unless $dev;
      open(my $fd, ">", $dev) or exit 1;
      binmode $fd;
      # EV_KEY=1, KEY_LEFTSHIFT=42, EV_SYN=0
      print $fd make_event(1, 42, 1);  # press
      print $fd make_event(0, 0, 0);   # sync
      print $fd make_event(1, 42, 0);  # release
      print $fd make_event(0, 0, 0);   # sync
      close($fd);
    '
  '';

  # Checks if a display is physically connected (regardless of enabled/disabled)
  isConnected = display: ''cat /sys/class/drm/card1-${display}/status 2>/dev/null | grep -q "^connected$"'';

  # kscreen-doctor needs Wayland session context to work
  waylandEnv = ''
    export WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-wayland-0}
    export QT_QPA_PLATFORM=wayland
    export XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/${toString uid}}
  '';

  # Prep-cmd "do": activate dummy plug for streaming
  #   1. Wake display from DPMS
  #   2. Enable dummy plug
  #   3. If main display is connected, disable it (so Sunshine streams the dummy plug only)
  streamStart = pkgs.writeShellScript "sunshine-stream-start" ''
    ${waylandEnv}
    ${wakeDisplay} || true
    sleep 1
    ${kscreen} output.${dummyDisplay}.enable output.${dummyDisplay}.mode.${streamResolution}
    if ${isConnected mainDisplay}; then
      ${kscreen} output.${mainDisplay}.disable
    fi
  '';

  # Prep-cmd "undo": restore normal display setup
  #   - If main display is connected, enable it and disable dummy plug
  #   - If main display is absent (headless), keep dummy plug enabled
  streamStop = pkgs.writeShellScript "sunshine-stream-stop" ''
    ${waylandEnv}
    if ${isConnected mainDisplay}; then
      ${kscreen} output.${mainDisplay}.enable output.${dummyDisplay}.disable
    fi
  '';

  # On Sunshine service start: ensure the right display is active
  #   - If main display is connected, use it and disable dummy plug
  #   - If headless (only dummy plug), enable dummy plug
  sunshinePreStart = pkgs.writeShellScript "sunshine-prestart" ''
    ${waylandEnv}
    ${wakeDisplay} || true
    sleep 1
    if ${isConnected mainDisplay}; then
      ${kscreen} output.${mainDisplay}.enable output.${dummyDisplay}.disable
    else
      ${kscreen} output.${dummyDisplay}.enable
    fi
  '';

  # Sunshine configuration file
  sunshineConf = pkgs.writeText "sunshine.conf" ''
    origin_web_ui_allowed = wan
    upnp = enabled
    output_name = 0
  '';

  # Sunshine apps configuration with dummy plug toggle hooks
  sunshineApps = pkgs.writeText "apps.json" (builtins.toJSON {
    env = {
      PATH = "$(PATH):$(HOME)/.local/bin";
    };
    apps = [
      {
        name = "Remote Desktop";
        image-path = "desktop.png";
        prep-cmd = [
          { do = "${streamStart}"; undo = "${streamStop}"; }
        ];
      }
      {
        name = "Spy on Desktop";
        image-path = "desktop.png";
      }
      {
        name = "Steam Big Picture";
        image-path = "steam.png";
        prep-cmd = [
          { do = "${streamStart}"; undo = "${streamStop}"; }
        ];
        detached = [
          "setsid steam steam://open/bigpicture"
        ];
      }
    ];
  });
in {
  # Custom EDID with 2273x1080@60Hz (Moonlight "native" for Xiaomi 15 Ultra)
  # for dummy plug streaming. Built manually because edid-generator rejects non-standard ratios.
  hardware.display.edid.packages = [
    (pkgs.runCommand "edid-2273x1080" { nativeBuildInputs = [ pkgs.perl ]; } ''
      mkdir -p $out/lib/firmware/edid
      perl -e '
        # Build a 128-byte EDID block for 2273x1080@60Hz
        # Based on GTF timing for 2272x1080: pclk=205.00MHz, with H active=2273
        my @edid = (0) x 128;

        # Header
        @edid[0..7] = (0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00);
        # Manufacturer + product
        @edid[8..9] = (0x3A, 0xF2);
        @edid[10..11] = (0x01, 0x00);
        @edid[12..15] = (0x01, 0x00, 0x00, 0x00);
        @edid[16] = 1; @edid[17] = 34;  # Week 1, Year 2024
        @edid[18] = 1; @edid[19] = 4;   # EDID 1.4

        # Digital, 8bpc, DisplayPort
        @edid[20] = 0xA5;
        @edid[21] = 49; @edid[22] = 23;  # 490mm x 233mm
        @edid[23] = 120;  # Gamma 2.2
        @edid[24] = 0x06;

        # Chromaticity (sRGB)
        @edid[25..34] = (0xEE, 0x91, 0xA3, 0x54, 0x4C, 0x99, 0x26, 0x0F, 0x50, 0x54);
        @edid[35..37] = (0x00, 0x00, 0x00);
        for my $i (38..53) { $edid[$i] = 0x01; }

        # DTD: 2273x1080@60Hz, pclk=205.00MHz
        my $pclk = 20500;
        @edid[54] = $pclk & 0xFF; @edid[55] = ($pclk >> 8) & 0xFF;
        my ($ha, $hb) = (2273, 784);
        @edid[56] = $ha & 0xFF;
        @edid[57] = $hb & 0xFF;
        @edid[58] = (($ha >> 4) & 0xF0) | (($hb >> 8) & 0x0F);
        my ($va, $vb) = (1080, 38);
        @edid[59] = $va & 0xFF;
        @edid[60] = $vb & 0xFF;
        @edid[61] = (($va >> 4) & 0xF0) | (($vb >> 8) & 0x0F);
        my ($hso, $hsw) = (144, 248);
        @edid[62] = $hso & 0xFF;
        @edid[63] = $hsw & 0xFF;
        my ($vso, $vsw) = (1, 3);
        @edid[64] = (($vso & 0x0F) << 4) | ($vsw & 0x0F);
        @edid[65] = (($hso >> 2) & 0xC0) | (($hsw >> 4) & 0x30) | (($vso >> 2) & 0x0C) | (($vsw >> 4) & 0x03);
        my ($hmm, $vmm) = (490, 233);
        @edid[66] = $hmm & 0xFF;
        @edid[67] = $vmm & 0xFF;
        @edid[68] = (($hmm >> 4) & 0xF0) | (($vmm >> 8) & 0x0F);
        @edid[69] = 0; @edid[70] = 0;
        @edid[71] = 0x1A;

        # Monitor name
        @edid[72..75] = (0x00, 0x00, 0x00, 0xFC);
        @edid[76] = 0x00;
        my @name = map { ord($_) } split(//, "NXS 2273x1080");
        push @name, 0x0A;
        while (scalar @name < 13) { push @name, 0x20; }
        @edid[77..89] = @name[0..12];

        # Monitor range limits
        @edid[90..93] = (0x00, 0x00, 0x00, 0xFD);
        @edid[94] = 0x00;
        @edid[95] = 56; @edid[96] = 76; @edid[97] = 30; @edid[98] = 80;
        @edid[99] = 21; @edid[100] = 0x00;
        @edid[101..107] = (0x0A, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20);

        # Empty descriptor
        @edid[108..125] = (0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
        @edid[126] = 0;

        my $sum = 0; $sum += $_ for @edid[0..126];
        $edid[127] = (256 - ($sum % 256)) % 256;

        # Write binary
        print pack("C*", @edid);
      ' > $out/lib/firmware/edid/2273x1080.bin
    '')
  ];
  hardware.display.outputs.${dummyDisplay}.edid = "2273x1080.bin";

  environment.systemPackages = with pkgs; [
    sunshine
    libva
    libva-utils
    libva-vdpau-driver
    libvdpau-va-gl
  ];

  # Grant cap_sys_admin for KMS display capture
  security.wrappers.sunshine = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+p";
    source = "${pkgs.sunshine}/bin/sunshine";
  };

  # Use a user service so Sunshine starts with the Wayland session
  systemd.user.services.sunshine = {
    description = "Sunshine Game Streaming Server";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStartPre = "${sunshinePreStart}";
      ExecStart = "/run/wrappers/bin/sunshine ${sunshineConf}";
      Restart = "on-failure";
      RestartSec = 5;
      WorkingDirectory = "/home/${username}";
      Environment = "XDG_RUNTIME_DIR=/run/user/${toString uid}";
    };
  };

  # Deploy apps.json declaratively
  systemd.user.tmpfiles.rules = [
    "L+ /home/${username}/.config/sunshine/apps.json - - - - ${sunshineApps}"
  ];

  networking.firewall = {
    allowedTCPPorts = [ 47984 47989 47990 48010 ];
    allowedUDPPorts = [
      47998
      47999
      48000
      8000
      8001
      8002
      8003
      8004
      8005
      8006
      8007
      8008
      8009
      8010
    ];
  };

  hardware.graphics = lib.mkForce {
    enable = true;
    extraPackages = with pkgs; [ libva-vdpau-driver libvdpau-va-gl mesa ];
  };
}
