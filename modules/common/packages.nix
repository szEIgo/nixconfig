{
  config,
  lib,
  pkgs,
  ...
}: {

  imports = [
    ./zsh.nix
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
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
  ];

}
