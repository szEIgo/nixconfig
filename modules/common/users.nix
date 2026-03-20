# Desktop user groups: extends core/users.nix with virtualization and desktop groups
# Only import this on desktop/workstation machines
{ config, lib, pkgs, ... }:

{
  users.users.joni.extraGroups = [
    "libvirtd"
    "kvm"
    "podman"
    "input"
    "video"
    "seat"
  ];

  systemd.tmpfiles.rules = [
    "d /mnt/files 0755 joni joni -"
  ];
}
