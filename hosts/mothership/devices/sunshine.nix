{ config, pkgs, lib, ... }:

let
  username = "joni";
  uid = 1000;
in {
  environment.systemPackages = with pkgs; [
    sunshine
    libva
    libva-utils
    vaapiVdpau
    libvdpau-va-gl
  ];

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

  networking.firewall.allowedTCPPorts = [ 47990 ];

  hardware.opengl = lib.mkForce {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [ vaapiVdpau libvdpau-va-gl mesa.drivers ];
  };
}
