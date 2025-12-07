{ config, lib, pkgs, ... }: {

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    gh
    sops
    android-tools
    qtscrcpy
    fzf
    zoxide
    zsh
    eza
    bat
    age
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
    jq
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
    fd
    kubectl
    wireguard-tools
    atop
    netdata
    plantuml
    jdk
    graphviz
  ];

  programs.zsh.enable = true;

}
