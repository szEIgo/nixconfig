{ config, pkgs, lib, ... }:

{
  # Open WebUI — self-hosted ChatGPT-like interface with Claude support
  # Access via http://<hostname>:3000
  virtualisation.oci-containers = {
    backend = "podman";
    containers.open-webui = {
      image = "ghcr.io/open-webui/open-webui:main";
      ports = [ "3000:8080" ];
      volumes = [
        "open-webui:/app/backend/data"
      ];
      environment = {
        # Disable default OpenAI integration (configure Claude via the UI)
        OPENAI_API_BASE_URL = "";
        OPENAI_API_KEY = "";
        # Enable speech features
        AUDIO_STT_ENGINE = "web";   # Browser-based STT by default
      };
    };
  };

  # Firewall — allow access to Open WebUI
  networking.firewall.allowedTCPPorts = [ 3000 ];
}
