{
  description = "Simple modular NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }: let
    systems = nixpkgs.lib.systems;
  in {
    nixosConfigurations = {
      mothership = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./hosts/mothership/configuration.nix
          ./hosts/mothership/hardware.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = {
               plasmaEnabled = true;
               #variableName = true/false (to be used e.g. joni.nix to conditionally set configs)
            };

            home-manager.users.joni = { config, pkgs, ... }: {
              home.username = "joni";
              home.homeDirectory = "/home/joni";
              imports = [ ./home/joni.nix ];
            };
          }
        ];
      };
    };

    homeConfigurations = {
      "joni@jsz-mac-01.nine.dk" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
        };
        modules = [
          {
            home.username = "joni";
            home.homeDirectory = "/Users/joni";
            _module.args.plasmaEnabled = false; # or omit entirely
          }
          ./home/joni.nix
        ];
      };
    };
  };
}
