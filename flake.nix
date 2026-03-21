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

    plasma-manager.url = "github:nix-community/plasma-manager";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager.inputs.home-manager.follows = "home-manager";
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, sops-nix, nixvirt, microvm, plasma-manager, ... }: {

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
            home-manager.users.joni = {
              imports = [
                plasma-manager.homeModules.plasma-manager
                ./home/joni.nix
              ];
            };
          }
        ];
      };

      # --- NixOS Configuration for Intel NUC (k3s worker) ---
      nuc = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Core modules
          ./modules/core

          # Host-specific configuration
          ./hosts/nuc/configuration.nix
          ./hosts/nuc/hardware.nix

          # Home Manager (shell config, no desktop)
          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = {
              plasmaEnabled = false;
              isLinux = true;
              isDarwin = false;
            };
            home-manager.users.joni = {
              imports = [ ./home/joni.nix ];
            };
          }
        ];
      };

      # --- NixOS Configuration for ThinkPad T480 (laptop) ---
      t480 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Core modules
          ./modules/core

          # Host-specific configuration
          ./hosts/t480/configuration.nix
          ./hosts/t480/hardware.nix

          # Home Manager with Plasma
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
            home-manager.users.joni = {
              imports = [
                plasma-manager.homeModules.plasma-manager
                ./home/joni.nix
              ];
            };
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
