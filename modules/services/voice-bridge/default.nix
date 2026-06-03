{ config, pkgs, lib, ... }:

let
  python = pkgs.python3.withPackages (ps: with ps; [
    fastapi
    uvicorn
    websockets
  ]);

  voice-bridge = pkgs.runCommand "voice-bridge" { } ''
    mkdir -p $out
    cp ${./app.py} $out/app.py
    cp ${./index.html} $out/index.html
  '';

  certDir = "/var/lib/voice-bridge/tls";
in
{
  # Claude Voice Bridge — voice-enabled web interface for claude CLI
  # Access via https://<hostname>:3001
  systemd.services.voice-bridge-cert = {
    description = "Generate self-signed TLS cert for Voice Bridge";
    wantedBy = [ "multi-user.target" ];
    before = [ "voice-bridge.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p ${certDir}
      if [ ! -f ${certDir}/key.pem ]; then
        ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:2048 \
          -keyout ${certDir}/key.pem -out ${certDir}/cert.pem \
          -days 3650 -nodes \
          -subj "/CN=mothership" \
          -addext "subjectAltName=DNS:mothership,DNS:localhost,IP:192.168.2.62,IP:192.168.10.1,IP:127.0.0.1"
        chown joni:users ${certDir}/key.pem ${certDir}/cert.pem
      fi
    '';
  };

  systemd.services.voice-bridge = {
    description = "Claude Voice Bridge";
    after = [ "network.target" "voice-bridge-cert.service" ];
    requires = [ "voice-bridge-cert.service" ];
    wantedBy = [ "multi-user.target" ];

    path = with pkgs; [ claude-code bash coreutils ];

    environment = {
      HOME = "/home/joni";
    };

    serviceConfig = {
      ExecStart = "${python}/bin/uvicorn app:app --host 0.0.0.0 --port 3001 --app-dir ${voice-bridge} --ssl-keyfile ${certDir}/key.pem --ssl-certfile ${certDir}/cert.pem";
      User = "joni";
      Group = "users";
      Restart = "always";
      RestartSec = 5;
    };
  };

  networking.firewall.allowedTCPPorts = [ 3001 ];
}
