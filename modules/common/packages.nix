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
    jq
    sbt
    scala
    rustc
    cargo
    rustfmt
  ];
  
  programs.zsh.enable = true;

}
