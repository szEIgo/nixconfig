{
  description = "Jonis Flaked NixConfig for Mothership / Macbook / Android";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, sops-nix, ... }: {

    # --- NixOS Configuration for Mothership ---
    nixosConfigurations = {
      mothership = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/mothership/configuration.nix
          ./hosts/mothership/hardware.nix
          sops-nix.nixosModules.sops
          ./secrets/secrets.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = {
              plasmaEnabled = true;
              isLinux = true;
              isDarwin = false;
            };
            home-manager.users.joni = { imports = [ ./home/joni.nix ]; };
          }
        ];
      };
    };

    # --- nix-darwin Configuration for Macbook ---
    darwinConfigurations = {
      "jsz-mac-01" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./hosts/macbook/default.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = {
              plasmaEnabled = false;
              isLinux = false;
              isDarwin = true;
            };
            home-manager.users.joni = { imports = [ ./home/joni.nix ]; };
          }
        ];
      };
    };
  };
}
