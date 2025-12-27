{ config, pkgs, lib, ... }:

let
  username = "joni";
  uid = 1000;
in {
  environment.systemPackages = with pkgs; [
    sunshine
    libva
    libva-utils
    libva-vdpau-driver    
    libvdpau-va-gl
  ];

  # Use a user service so Sunshine starts with the Wayland session
  systemd.user.services.sunshine = {
    description = "Sunshine Game Streaming Server";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.sunshine}/bin/sunshine";
      Restart = "on-failure";
      WorkingDirectory = "/home/${username}";
      Environment = "XDG_RUNTIME_DIR=/run/user/${toString uid}";
    };
  };

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
