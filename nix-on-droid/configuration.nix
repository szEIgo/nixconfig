# ./nix-on-droid/configuration.nix
{ pkgs, ... }: {
  # Packages needed for a basic environment on Android
  environment.packages = with pkgs; [
    vim
    git
    openssh
    procps # Provides killall, etc.
  ];

  # Basic system settings
  system.stateVersion = "24.05";
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  time.timeZone = "Europe/Copenhagen";
}
