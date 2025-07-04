# ./nix-on-droid/flake.nix
{
  description = "Joni's Nix-on-Droid Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # This special input reaches "outside" the flake to the parent directory
    # to access the shared home-manager configuration.
    nixconfig.url = "path:..";
    nixconfig.flake = false;
  };

  outputs = { self, nixpkgs, home-manager, nix-on-droid, nixconfig }: {
    nixOnDroidConfigurations = {
      android = nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = import nixpkgs { system = "aarch64-linux"; };
        extraSpecialArgs = {
          # Pass the repo root for consistent paths in modules
          root = nixconfig;
        };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { root = nixconfig; }; # Pass root to HM modules
            home-manager.users.joni = {
              # Import the shared user config using the path from the input
              imports = [ "${nixconfig}/home-manager/joni.nix" ];
            };
          }
        ];
      };
    };
  };
}
