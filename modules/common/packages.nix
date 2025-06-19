{
  config,
  lib,
  pkgs,
  ...
}: {


  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    zoxide
    zsh
    eza
    bat
    age
    zsh-history
    librewolf
    keychain
    vim
    btop
    wget
    pciutils
    nmap
    haskellPackages.Xauth
    vscodium
    ripgrep
    jqhome
    sbt
    scala
    rustc
    cargo
    rustfmt
    ncdu
    tree
    dust
    tmux
    byobu
    helix	
    copyq
    parted
    usbutils
    gptfdisk
    woeusb-ng
  ];
  
  programs.zsh.enable = true;

}
