# Custom NixOS installer ISO for worker nodes
# Boots with sshd running + joni's SSH keys — ready for nixos-anywhere
{ config, lib, pkgs, modulesPath, ... }:

let
  authorizedKeysFile = ../../remote/authorized_keys;
  authorizedKeys = lib.lists.filter (key: key != "") (
    lib.strings.splitString "\n" (builtins.readFile authorizedKeysFile)
  );
in {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  # Start sshd automatically
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # Deploy joni's SSH keys so nixos-anywhere can connect without password
  users.users.root.openssh.authorizedKeys.keys = authorizedKeys;

  # ZFS support for future disk layouts
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "00000000"; # Placeholder, required for ZFS

  # Useful for debugging during install
  environment.systemPackages = with pkgs; [ git vim htop ];
}
