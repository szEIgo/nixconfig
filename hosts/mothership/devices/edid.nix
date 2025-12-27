{ pkgs, ... }:
let
  edidFirmware = pkgs.stdenv.mkDerivation {
    name = "virtual-edid";
    src = ./edid/virtual-1080p.bin;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/lib/firmware/edid
      cp $src $out/lib/firmware/edid/virtual-1080p.bin
    '';
  };
in {
  boot.initrd.firmware = [ edidFirmware ];
}
