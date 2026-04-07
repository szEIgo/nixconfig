{ lib, stdenv, fetchurl, autoPatchelfHook, alsa-lib, openssl }:

stdenv.mkDerivation rec {
  pname = "claurst";
  version = "0.0.8";

  src = fetchurl {
    url = "https://github.com/Kuberwastaken/claurst/releases/download/v${version}/claurst-linux-x86_64.tar.gz";
    hash = "sha256-XrSxDF8v2pk6E/qVCutUsIdQaIu1dO6YzuwujILTyhA=";
  };

  dontUnpack = true;

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    alsa-lib              # libasound.so.2
    openssl               # libssl.so.3, libcrypto.so.3
    stdenv.cc.cc.lib      # libgcc_s.so.1
  ];

  installPhase = ''
    mkdir -p $out/bin
    tar xzf $src -C $out/bin
    mv $out/bin/claurst-linux-x86_64 $out/bin/claurst
    chmod 755 $out/bin/claurst
  '';

  meta = with lib; {
    description = "Open-source, multi-provider terminal coding agent";
    homepage = "https://github.com/Kuberwastaken/claurst";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "claurst";
  };
}
