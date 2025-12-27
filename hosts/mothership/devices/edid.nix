{ pkgs, ... }:
let
  edidFirmware = pkgs.stdenv.mkDerivation {
    name = "virtual-edid-2048x1332";
    src = ./edid/virtual-2048x1332.bin;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/lib/firmware/edid
      cp $src $out/lib/firmware/edid/virtual-2048x1332.bin
    '';
  };
in {
  boot.initrd.firmware = [ edidFirmware ];
}
