# Custom NixOS installer ISO for fleet nodes
# Boots with sshd running + SSH keys — ready for nixos-anywhere
#
# Features:
#   - sshd with authorized keys (no password needed)
#   - Prints IP address on console after boot
#   - Sends UDP announcement to mothership (192.168.2.62:9999)
#   - ZFS support for disk layout
{ config, lib, pkgs, modulesPath, ... }:

let
  authorizedKeysFile = ../../remote/authorized_keys;
  authorizedKeys = lib.lists.filter (key: key != "") (
    lib.strings.splitString "\n" (builtins.readFile authorizedKeysFile)
  );

  # Script that announces this node's IP to the mothership via UDP
  announceScript = pkgs.writeShellScriptBin "fleet-announce" ''
    MOTHERSHIP="192.168.2.62"
    PORT=9999
    IFACE_IP=""

    # Wait for a routable IP (up to 60s)
    for i in $(seq 1 60); do
      IFACE_IP=$(${pkgs.iproute2}/bin/ip -4 addr show scope global | ${pkgs.gawk}/bin/awk '/inet / {split($2,a,"/"); print a[1]; exit}')
      if [ -n "$IFACE_IP" ]; then
        break
      fi
      sleep 1
    done

    if [ -z "$IFACE_IP" ]; then
      echo "fleet-announce: no IP address found after 60s"
      exit 1
    fi

    MAC=$(${pkgs.iproute2}/bin/ip link show | ${pkgs.gawk}/bin/awk '/ether/ {print $2; exit}')
    MSG="FLEET_READY|ip=$IFACE_IP|mac=$MAC"

    # Announce every 10s for 5 minutes (in case mothership isn't listening yet)
    for i in $(seq 1 30); do
      echo "$MSG" | ${pkgs.socat}/bin/socat - UDP4-DATAGRAM:$MOTHERSHIP:$PORT
      sleep 10
    done
  '';

  # Script to display IP prominently on the console
  showIpScript = pkgs.writeShellScriptBin "show-ip" ''
    for i in $(seq 1 30); do
      IP=$(${pkgs.iproute2}/bin/ip -4 addr show scope global | ${pkgs.gawk}/bin/awk '/inet / {split($2,a,"/"); print a[1]; exit}')
      if [ -n "$IP" ]; then
        echo ""
        echo "==========================================="
        echo "  FLEET NODE READY — Protoss Fleet Installer"
        echo "  IP: $IP"
        echo "  SSH: ssh root@$IP"
        echo "==========================================="
        echo ""
        break
      fi
      sleep 2
    done
  '';
in {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  # Custom ISO naming
  isoImage.isoBaseName = lib.mkForce "fleet-installer";
  isoImage.appendToMenuLabel = " - Fleet Node Installer";

  # Force sshd on with root login via keys (override installer defaults)
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = lib.mkForce "yes";
  };

  # Deploy SSH keys so nixos-anywhere can connect without password
  users.users.root = {
    openssh.authorizedKeys.keys = authorizedKeys;
    # Allow root login on console without password (for debugging if needed)
    initialHashedPassword = lib.mkForce "";
  };

  # Also set nixos user keys (the installer auto-logs in as nixos)
  users.users.nixos.openssh.authorizedKeys.keys = authorizedKeys;

  # Show fleet banner only on physical console (tty), not SSH sessions
  programs.bash.loginShellInit = ''
    if [[ "$(tty)" == /dev/tty* ]]; then
      ${showIpScript}/bin/show-ip
    fi
  '';

  # ZFS support for disk layout
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "00000000";

  # Display IP on console via systemd (also writes to journal)
  systemd.services.show-ip = {
    description = "Display IP address on console";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${showIpScript}/bin/show-ip";
      StandardOutput = "journal+console";
    };
  };

  # Announce presence to mothership via UDP
  systemd.services.fleet-announce = {
    description = "Announce fleet node to mothership";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${announceScript}/bin/fleet-announce";
      Restart = "on-failure";
      RestartSec = "30";
    };
  };

  # Useful for debugging during install
  environment.systemPackages = with pkgs; [ git vim htop socat ];
}
