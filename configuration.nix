{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;



  
  boot.loader.efi.canTouchEfiVariables = true;


   networking.hostName = "mothership"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
   time.timeZone = "Europe/Copenhagen";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   keyMap = "da";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
   services.xserver.enable = true;


  

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
   #hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };


   users.users.joni = {
     isNormalUser = true;
     extraGroups = [ "wheel" "libvirtd" ]; # Enable ‘sudo’ for the user.
     packages = with pkgs; [
       tree
     ];
   };




 # virtualisation.kvm.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [(pkgs.OVMF.override {
          secureBoot = true;
          tpmSupport = true;
        }).fd];
      };
    };
  };
 # services.libvirtd.wheelGroup = "kvm";


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
   #  ovmf
     plasma-browser-integration
     konsole
     oxygen
     git 
   ];

   programs.steam.enable = true;
   programs.steam.gamescopeSession.enable = true;
   programs.gamemode.enable = true;
#   environment.systemPackages = with pkgs; [mangohud protonup-qt lutris bottles heroic];


   programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
   };

   services.xserver.videoDrivers = ["amdgpu"];
   services.displayManager.sddm.enable = true;
   services.displayManager.sddm.wayland.enable = true;
   security.polkit.enable = true;
   services.desktopManager.plasma6.enable = true;
   services.desktopManager.plasma6.enableQt5Integration = false;


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

   system.stateVersion = "24.11"; # Did you read the comment?

}

