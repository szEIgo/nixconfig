# Network topology for nix-topology diagram generation
# Build: nix build .#topology.x86_64-linux.config.output
{ config, ... }: {

  # Define the home LAN
  networks.lan = {
    name = "Home LAN";
    cidrv4 = "192.168.2.0/24";
  };

  # WireGuard VPN
  networks.wireguard = {
    name = "WireGuard VPN";
    cidrv4 = "192.168.10.0/24";
    style.primaryColor = "#88c0d0";
  };

  # k3s cluster overlay
  networks.k3s = {
    name = "k3s Cluster (Flannel)";
    cidrv4 = "10.42.0.0/16";
    style.primaryColor = "#a3be8c";
  };
}
