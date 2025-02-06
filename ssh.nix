{ config, lib, pkgs, ... }:
{
programs.ssh = {
    forwardX11 = true;
    setXAuthLocation = true;
#    X11DisplayOffset = 10;
   };


   services.openssh = {
     enable = true;
     settings.PermitRootLogin = "yes";
   };
   users.users."joni".openssh.authorizedKeys.keyFiles = [
      /etc/nixos/ssh/authorized_keys
   ];


}