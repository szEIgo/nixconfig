{
  description = "Jonis Flaked NixConfig for Mothership / Macbook / Android";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  # The outputs function now takes all the new inputs
  outputs = { self, nixpkgs, home-manager, ... }: {

    # --- NixOS Configuration for Mothership (uses 25.05) ---
    nixosConfigurations = {
      mothership = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/mothership/configuration.nix
          ./hosts/mothership/hardware.nix
          home-manager.nixosModules.home-manager # Uses the main 25.05 home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { plasmaEnabled = true; };
            home-manager.users.joni = { imports = [ ./home/joni.nix ]; };
          }
        ];
      };
    };

    # --- Home Manager for macOS (uses 25.05) ---
    homeConfigurations = {
      "joni@jsz-mac-01.nine.dk" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        extraSpecialArgs = { plasmaEnabled = false; };
        modules = [
          ./home/joni.nix
          {
            home.username = "joni";
            home.homeDirectory = "/Users/joni";
            home.stateVersion = "25.05";
          }
        ];
      };
    };
  };
}
