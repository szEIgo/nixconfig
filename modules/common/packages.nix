# Common system packages for NixOS desktops/workstations
# CLI tools are now in home/profiles/base.nix (home-manager)
# This is for NixOS system-level packages only
{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gnumake
    net-tools
    kustomize
    fluxcd
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
    vim
    btop
    wget
    pciutils
    nmap
    haskellPackages.Xauth
    vscode
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

}
