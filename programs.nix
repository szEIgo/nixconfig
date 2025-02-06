{ config, lib, pkgs, ... }:
{

   nix.settings.experimental-features = [ "nix-command" "flakes" ];
   nixpkgs.config.allowUnfree = true;
   environment.systemPackages = with pkgs; [
     vim
     btop
     wget
     virt-manager
     qemu
     libvirt
     pciutils
     nmap
     kmod
     xorg.xauth
     kwin
     plasma-browser-integration
     konsole
     oxygen
     git
   ];
   hardware.steam-hardware.enable = true;
   programs = {
         xwayland.enable = true;
         steam = {
             enable = true;
             gamescopeSession.enable = true;
             package = pkgs.steam.override {
               extraPkgs = (pkgs: with pkgs; [
                 gamemode
               ]);
             };
         };
         gamemode = {
                enable = true;
                enableRenice = true;
                settings = {
                  general = {
                    softrealtime = "auto";
                    renice = 10;
                  };
                  custom = {
                    start = "notify-send -a 'Gamemode' 'Optimizations activated'";
                    end = "notify-send -a 'Gamemode' 'Optimizations deactivated'";
                  };
                };
        };

        gnupg.agent = {
             enable = true;
             enableSSHSupport = true;
        };
   };
}