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
     listenAddresses = [
     	{ addr = "0.0.0.0"; port = 22; }
     ];
     settings = {
       PermitRootLogin = "prohibit-password";
       X11Forwarding = true;
       Macs = [
    	"hmac-sha2-512"
    	"hmac-sha2-256"
    	"hmac-sha1"
       ];
    };
   };
   users.users."joni".openssh.authorizedKeys.keyFiles = [
      ./authorized_keys
   ];
   users.users.root.openssh.authorizedKeys.keyFiles = [
     ./authorized_keys
   ];
}
