# ./home-manager/modules/nixos.nix
# This module is imported by NixOS to configure Home Manager.
{ root, ... }: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit root; };
    users.joni = {
      imports = [
        "${root}/home-manager/joni.nix"
        # Import plasma dotfiles only for the mothership user
        "${root}/home-manager/modules/plasma.nix"
      ];
    };
  };
}
