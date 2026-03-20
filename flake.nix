{
  description = "Jonis NixConfig - Multi-platform: NixOS, macOS, Raspberry Pi";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nixvirt.url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
    nixvirt.inputs.nixpkgs.follows = "nixpkgs";

    microvm.url = "github:astro/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, sops-nix, nixvirt, microvm, ... }: {

    # --- NixOS Configuration for Mothership ---
    nixosConfigurations = {
      mothership = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Core modules
          ./modules/core

          # Host-specific configuration
          ./hosts/mothership/configuration.nix
          ./hosts/mothership/hardware.nix

          # Secrets
          sops-nix.nixosModules.sops
          ./secrets/secrets.nix

          # Virtualization
          microvm.nixosModules.host
          nixvirt.nixosModules.default

          # Home Manager
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
