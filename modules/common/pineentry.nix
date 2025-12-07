{ config, pkgs, ... }:

{
  # 1. Enable the GnuPG agent service
  services.gpg-agent = {
    enable = true;
    # Set the pinentry program to use the TTY (terminal) version
    pinentryFlavor = "tty";
    # Start the agent automatically when needed
    enableSshSupport = true; # Optional, but generally useful for SSH
  };

  # 2. Ensure GnuPG itself is installed in your user environment
  home.packages = with pkgs; [
    gnupg
  ];
}
