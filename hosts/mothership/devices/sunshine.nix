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

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  systemd.services.sunshine = {
    description = "Sunshine Game Streaming Server";
    after = [ "network.target" "graphical.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.sunshine}/bin/sunshine";
      Restart = "on-failure";
      User = username;
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
