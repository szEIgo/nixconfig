# ./home-manager/modules/cli/default.nix
{ root, ... }: {
  imports = [
    "${root}/home-manager/modules/cli/zsh.nix"
    # You can add more CLI module imports here, e.g., for tmux
  ];
}
