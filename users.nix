{ config, lib, pkgs, ... }:
{
 users.users.joni = {
     isNormalUser = true;
     extraGroups = [ "wheel" "libvirtd" ]; # Enable ‘sudo’ for the user.
     packages = with pkgs; [
       tree
     ];
   };

}