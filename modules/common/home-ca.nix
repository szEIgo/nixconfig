# Trust the Szigethy Home CA on all machines
# This makes browsers (Firefox, Chrome) and CLI tools trust *.szigethy.lan certs
{ config, lib, pkgs, ... }: {
  security.pki.certificateFiles = [
    ../../secrets/szigethy-home-ca.crt
  ];
}
