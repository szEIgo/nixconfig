{ config, lib, pkgs, ... }:
let
   username = "joni";
   uid = 1000;
in {
   systemd.user.services.wayvnc = {
      description = "WayVNC (Wayland VNC server for Hyprland)";
      after = [ "graphical-session.target" "hyprland-session.target" ];
      requires = [ "hyprland-session.target" ];
      wantedBy = [ ];
      serviceConfig = {
         ExecStart = "${pkgs.wayvnc}/bin/wayvnc 127.0.0.1 5900 -o HEADLESS-1 -L info";
         Restart = "on-failure";
         Environment = [
            "XDG_RUNTIME_DIR=/run/user/${toString uid}"
         ];
         WorkingDirectory = "/home/${username}";
      };
   };
}
