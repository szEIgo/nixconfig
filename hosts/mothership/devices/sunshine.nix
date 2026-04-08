{ config, pkgs, lib, ... }:

let
  username = "joni";
  uid = 1000;
  kscreen = "${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor";

  # DP-1 = main "BIG" ultrawide (5120x1440@120Hz)
  # DP-2 = dummy plug for headless streaming (1920x1080@60Hz)
  mainDisplay = "DP-1";
  dummyDisplay = "DP-2";

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

  # Prep-cmd "do": activate dummy plug for streaming
  #   1. Wake display from DPMS
  #   2. Enable dummy plug
  #   3. If main display is connected, disable it (so Sunshine streams the dummy plug only)
  streamStart = pkgs.writeShellScript "sunshine-stream-start" ''
    ${wakeDisplay} || true
    sleep 1
    ${kscreen} output.${dummyDisplay}.enable output.${dummyDisplay}.mode.1920x1080@60
    if ${isConnected mainDisplay}; then
      ${kscreen} output.${mainDisplay}.disable
    fi
  '';

  # Prep-cmd "undo": restore normal display setup
  #   - If main display is connected, enable it and disable dummy plug
  #   - If main display is absent (headless), keep dummy plug enabled
  streamStop = pkgs.writeShellScript "sunshine-stream-stop" ''
    if ${isConnected mainDisplay}; then
      ${kscreen} output.${mainDisplay}.enable output.${dummyDisplay}.disable
    fi
  '';

  # On Sunshine service start: ensure the right display is active
  #   - If main display is connected, use it and disable dummy plug
  #   - If headless (only dummy plug), enable dummy plug
  sunshinePreStart = pkgs.writeShellScript "sunshine-prestart" ''
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
        name = "Desktop";
        image-path = "desktop.png";
        prep-cmd = [
          { do = "${streamStart}"; undo = "${streamStop}"; }
        ];
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
