{ config, lib, pkgs, ... }:

let
  joniKey = "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAHDfzNmhnlqZCZagsLq/GkTwTiMOGWE6VXhRuXI6aOgG8N1G49ux54s1VCAT94z/TutAkKI5w8Vl7jBI3Ph3CZwVAG6s8HlB513ap2lTESX+Hyw6aKa69YXbJIsMTD264pLzmSvBR0VuNzLXz/k7IeUm73Q8K6aR5yBWniJYZpJvLgdSQ== joni@mac";
in
{
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
    listenAddresses = [
      { addr = "0.0.0.0"; port = 22; }
    ];
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      X11Forwarding = true;
      AuthorizedKeysFile = "/etc/ssh/authorized_keys.d/%u";
      Macs = [
        "hmac-sha2-512"
        "hmac-sha2-256"
        "hmac-sha1"
      ];
    };
  };

  users.users = {
    joni.openssh.authorizedKeys.keys = [ joniKey ];
    root.openssh.authorizedKeys.keys = [ joniKey ];
  };
}
