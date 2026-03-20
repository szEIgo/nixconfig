{ config, lib, pkgs, ... }:

{
  virtualisation.libvirt = {
    enable = true;

    connections."qemu:///system".domains = [
      {
        definition = ./xml/win11-nvidia.xml;
        active = null;  # Don't auto-start
      }
      {
        definition = ./xml/win11-amd.xml;
        active = null;
      }
      {
        definition = ./xml/archlinux.xml;
        active = null;
      }
      {
        definition = ./xml/win11-goldenImage.xml;
        active = null;
      }
    ];
  };
}
