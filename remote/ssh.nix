{ config, lib, pkgs, ... }:

let
  authorizedKeysFile = ./authorized_keys;

  authorizedKeys = lib.lists.filter (key: key != "") (
    lib.strings.splitString "
" (builtins.readFile authorizedKeysFile)
  );

in {
  programs = {
    ssh = {
      forwardX11 = true;
      setXAuthLocation = true;
    };
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  services.openssh = {
    enable = true;
    listenAddresses = [{
      addr = "0.0.0.0";
      port = 22;
    }];
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      X11Forwarding = true;
      AuthorizedKeysFile = "/etc/ssh/authorized_keys.d/%u";
      Macs = [ "hmac-sha2-512" "hmac-sha2-256" "hmac-sha1" ];
    };
  };

  users.users = {
    joni.openssh.authorizedKeys.keys = authorizedKeys;
    root.openssh.authorizedKeys.keys = authorizedKeys;
  };
}
