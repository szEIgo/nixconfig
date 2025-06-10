# modules/zfs.nix
{ config, lib, pkgs, ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
}