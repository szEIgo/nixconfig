{
  description = "Jonis NixConfig - Multi-platform: NixOS, macOS, Android";

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

    nix-on-droid.url = "github:szEIgo/joni-android/master";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.home-manager.follows = "home-manager";
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, sops-nix, nixvirt, microvm, plasma-manager, nix-on-droid, ... }:
  let
    # Git revision tracking — embedded in every NixOS system label
    gitRevision = self.shortRev or self.dirtyShortRev or "unknown";
    nixosRevisionModule = {
      system.configurationRevision = self.rev or self.dirtyRev or "dirty";
      system.nixos.label = "nixconfig-${gitRevision}";
    };
  in {

    # --- NixOS Configuration for Mothership ---
    nixosConfigurations = {
      mothership = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixosRevisionModule

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
              isAndroid = false;
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
          nixosRevisionModule

          # Core modules
          ./modules/core

          # Host-specific configuration
          ./hosts/nuc/configuration.nix
          ./hosts/nuc/hardware.nix

          # Secrets
          sops-nix.nixosModules.sops
          ./secrets/nuc.nix

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
              isAndroid = false;
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
          nixosRevisionModule

          # Core modules
          ./modules/core

          # Host-specific configuration
          ./hosts/t480/configuration.nix
          ./hosts/t480/hardware.nix

          # Secrets
          sops-nix.nixosModules.sops
          ./secrets/t480.nix

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
              isAndroid = false;
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
              isAndroid = false;
            };
            home-manager.users.joni = { imports = [ ./home/joni.nix ]; };
          }
        ];
      };
    };

    # --- Standalone Home Manager for OnePlus 6T (postmarketOS) ---
    homeConfigurations.oneplus6t = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs { system = "aarch64-linux"; };
      extraSpecialArgs = {
        plasmaEnabled = false;
        isLinux = true;
        isDarwin = false;
        isAndroid = false;
        isPostmarketOS = true;
      };
      modules = [
        ./home/joni.nix
        ./hosts/oneplus6t/default.nix
      ];
    };

    # --- nix-on-droid Configuration for Android ---
    nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
      pkgs = import nixpkgs { system = "aarch64-linux"; };
      modules = [
        ./hosts/android/default.nix
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            extraSpecialArgs = {
              plasmaEnabled = false;
              isLinux = true;
              isDarwin = false;
              isAndroid = true;
            };
            config = ./home/joni.nix;
          };
        }
      ];
    };
  };
}
