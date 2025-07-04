{
  description = "Jonis Flaked NixConfig for Mothership / Macbook / Android";

  inputs = {
    # --- Inputs for 25.05 Systems (Mothership, Mac) ---
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # --- Inputs for 24.05 System (Nix-on-Droid) ---
    # A separate nixpkgs input for the older version
    nixpkgs_24_05.url = "github:NixOS/nixpkgs/nixos-24.05";

    # A separate home-manager input that uses the 24.05 nixpkgs
    home-manager_24_05 = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs_24_05";
    };

    # The nix-on-droid input, now correctly using the 24.05 release
    # and following the 24.05 nixpkgs.
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs_24_05";
    };
  };

  # The outputs function now takes all the new inputs
  outputs = { self, nixpkgs, home-manager, nixpkgs_24_05, home-manager_24_05, nix-on-droid, ... }: {

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

    # --- Nix-on-Droid Configuration (uses 24.05) ---
    nixOnDroidConfigurations = {
      android = nix-on-droid.lib.nixOnDroidConfiguration {
        # Use the 24.05 version of pkgs
        pkgs = import nixpkgs_24_05 { system = "aarch64-linux"; };

        modules = [
          # Assuming you have this file from our previous step
          ./hosts/android/default.nix

          # Use the 24.05 version of the home-manager module
          home-manager_24_05.nixosModules.home-manager

          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { plasmaEnabled = false; };
            home-manager.users.joni = {
              # This line is the magic: it reuses your existing home config
              # but builds it with the 24.05 packages.
              imports = [ ./home/joni.nix ];
            };
          }
        ];
      };
    };
  };
}
