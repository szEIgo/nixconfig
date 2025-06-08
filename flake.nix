{
  description = "Simple modular NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.mothership = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          ./hosts/mothership/configuration.nix
          ./hosts/mothership/hardware.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.joni = import ./home/joni.nix;
          }
        ];
      };
    };
}
