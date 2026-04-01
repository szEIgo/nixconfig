# Local binary cache for the k3s fleet
# Fleet nodes pull pre-built closures from mothership over LAN
# instead of building locally or fetching from cache.nixos.org
{ config, lib, pkgs, ... }: {

  services.harmonia.cache = {
    enable = true;
    signKeyPaths = [ "/var/lib/harmonia/cache-priv-key.pem" ];
    settings.bind = "[::]:5000";
  };

  # Allow fleet nodes to reach the cache
  networking.firewall.allowedTCPPorts = [ 5000 ];

  # Generate signing key on first boot
  systemd.services.harmonia-keygen = {
    description = "Generate Harmonia signing key";
    wantedBy = [ "harmonia.service" ];
    before = [ "harmonia.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      KEY_DIR="/var/lib/harmonia"
      mkdir -p "$KEY_DIR"
      if [ ! -f "$KEY_DIR/cache-priv-key.pem" ]; then
        ${pkgs.nix}/bin/nix-store --generate-binary-cache-key \
          mothership-cache "$KEY_DIR/cache-priv-key.pem" "$KEY_DIR/cache-pub-key.pem"
        echo "Harmonia signing key generated"
        echo "Public key: $(cat $KEY_DIR/cache-pub-key.pem)"
      fi
    '';
  };
}
