{ config, lib, pkgs, ... }:
{
    programs =  {
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
     settings = {
       PermitRootLogin = "prohibit-password";
       X11Forwarding = true;
    };
   };
   users.users."joni".openssh.authorizedKeys.keyFiles = [
      /etc/nixos/remote/authorized_keys
   ];
   users.users.root.openssh.authorizedKeys.keyFiles = [
     /etc/nixos/remote/authorized_keys
   ];
}
