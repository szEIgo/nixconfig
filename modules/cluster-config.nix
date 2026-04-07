# Single source of truth for k3s cluster connection parameters.
# Imported by: keepalived, k3s.nix, and home-manager kubeconfig generation.
# Changing values here updates kubeconfigs and VIPs across all machines on rebuild.
{
  clusterName = "k3s-homelab";
  vip = "192.168.2.200";
  apiPort = 6443;
  apiEndpoint = "https://192.168.2.200:6443";
  mothershipIp = "192.168.2.62";

  # WireGuard server (mothership)
  wg = {
    endpoint = "80.209.114.19:51821";
    serverPublicKey = "vL6bB4f9ELSQc3OvDPWzFq5eEioUufxNvoqcUp/VX3U=";
    subnet = "192.168.10.0/24";
    dns = "192.168.10.1";
  };
}
