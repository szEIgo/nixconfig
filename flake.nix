{
  description = "Jonis NixConfig - Multi-platform: NixOS, macOS, Raspberry Pi";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Uncomment when ready to use nix-darwin for macOS
    # nix-darwin.url = "github:LnL7/nix-darwin";
    # nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, ... }:
  let
    # Helper to create NixOS configurations
    mkNixosHost = { system, hostName, hostType ? "desktop", extraModules ? [] }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # Core modules (required for all hosts)
          ./modules/core

          # Host-specific configuration
          ./hosts/${hostName}/configuration.nix
          ./hosts/${hostName}/hardware.nix

          # Secrets
          sops-nix.nixosModules.sops
          ./secrets/secrets.nix

          # Home-manager integration
          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = {
              inherit hostType;
              plasmaEnabled = hostType == "desktop";
            };
            home-manager.users.joni = { imports = [ ./home/joni.nix ]; };
          }
        ] ++ extraModules;
      };
  in
  {
    # NixOS Configurations
    nixosConfigurations = {
      mothership = mkNixosHost {
        system = "x86_64-linux";
        hostName = "mothership";
        hostType = "desktop";
      };
    };

    # Standalone Home Manager (for systems without NixOS/nix-darwin)
    homeConfigurations = {
      "joni@jsz-mac-01.nine.dk" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        extraSpecialArgs = {
          hostType = "workstation";
          plasmaEnabled = false;
        };
        modules = [
          ./home/joni.nix
          {
            home.username = "joni";
            home.homeDirectory = "/Users/joni";
            home.stateVersion = "25.11";
          }
        ];
      };
    };

    # Uncomment when ready to use nix-darwin
    # darwinConfigurations = {
    #   macbook = nix-darwin.lib.darwinSystem {
    #     system = "aarch64-darwin";
    #     modules = [
    #       ./darwin
    #       home-manager.darwinModules.home-manager
    #       {
    #         home-manager.useUserPackages = true;
    #         home-manager.useGlobalPkgs = true;
    #         home-manager.extraSpecialArgs = {
    #           hostType = "workstation";
    #           plasmaEnabled = false;
    #         };
    #         home-manager.users.joni = { imports = [ ./home/joni.nix ]; };
    #       }
    #     ];
    #   };
    # };
  };
}
