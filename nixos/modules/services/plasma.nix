# ./nixos/modules/services/plasma.nix
{ ... }: {
  # Enable the K Desktop Environment
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  services.xserver.enable = true;

  # Enable sound
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    jack.enable = true;
  };
}
