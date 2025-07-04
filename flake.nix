{
  description = "Jonis Flaked NixConfig for Mothership / Macbook / Android";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Add the new input for Nix-on-Droid
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-on-droid, ... }: {
    # NixOS Configuration for your server (no changes here)
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
            };
            home-manager.users.joni = {
              imports = [ ./home/joni.nix ];
            };
          }
        ];
      };
    };

    # Home Manager for macOS (no changes here)
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

    # --- NEW: Nix-on-Droid Configuration for your Android device ---
    nixOnDroidConfigurations = {
      # You can name this whatever you like, e.g., "my-phone"
      android = nix-on-droid.lib.nixOnDroidConfiguration {
        # Specify the system for your Android device
        pkgs = import nixpkgs { system = "aarch64-linux"; };
        
        modules = [
          # 1. Import the new Nix-on-Droid config file
          ./hosts/android/default.nix

          # 2. Import the Home Manager module
          home-manager.nixosModules.home-manager

          # 3. Configure Home Manager to use your existing joni.nix
          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = {
              # Ensure Plasma-specific settings are disabled on Android
              plasmaEnabled = false;
            };
            home-manager.users.joni = {
              imports = [ ./home/joni.nix ];
            };
          }
        ];
      };
    };
  };
}
