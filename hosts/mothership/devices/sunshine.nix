# /etc/nixos/hosts/mothership/devices/sunshine.nix
# This is the corrected version.

{ config, pkgs, lib, ... }:

let
  username = "joni";
  uid = 1000;
in
{
  # Install sunshine and its dependencies
  environment.systemPackages = with pkgs; [
    sunshine
    libva
    libva-utils
    vaapiVdpau
    libvdpau-va-gl
  ];

  # Add required graphics packages without overwriting the whole config.
  # This is the key change. We are merging these packages into the list.
  hardware.graphics.extraPackages = with pkgs; [
    vaapiVdpau
    libvdpau-va-gl
    mesa
  ];

  # Enable the sunshine service
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  # Configure the systemd service for sunshine
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

  # Open the necessary firewall ports
  networking.firewall.allowedTCPPorts = [ 47984 47989 47990 48010 ];
  networking.firewall.allowedUDPPorts = [
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
}
