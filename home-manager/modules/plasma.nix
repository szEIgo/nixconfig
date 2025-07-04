# ./home-manager/modules/plasma.nix
# This module cleanly links all your Plasma dotfiles.
{ root, ... }: {
  # This takes the entire contents of the 'plasma' dotfiles directory
  # and links it recursively into ~/.config
  home.file.".config/".source = "${root}/home-manager/dotfiles/plasma";
}
