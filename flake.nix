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

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, sops-nix, nixvirt, microvm, plasma-manager, nix-on-droid, disko, ... }:
  let
    # Git revision tracking — embedded in every NixOS system label
    gitRevision = self.shortRev or self.dirtyShortRev or "unknown";
    nixosRevisionModule = {
      system.configurationRevision = self.rev or self.dirtyRev or "dirty";
      system.nixos.label = "nixconfig-${gitRevision}";
    };

    # Default home-manager special args — override per host as needed
    defaultHomeArgs = {
      plasmaEnabled = false;
      isLinux = true;
      isDarwin = false;
      isAndroid = false;
      isPostmarketOS = false;
      isServer = false;
    };

    # Helper to create identical k3s worker nodes
    # bootMode: "legacy" (BIOS/GRUB) or "uefi" (GPT/systemd-boot)
    mkWorker = hostname: { bootMode ? "legacy", disk ? "/dev/sda", extraModules ? [] }: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixosRevisionModule
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        ./modules/core
        ./hosts/worker/disko.nix
        ./hosts/worker/configuration.nix
        ./hosts/worker/hardware.nix
        ./secrets/worker.nix
        {
          networking.hostName = hostname;
          local.worker = { inherit bootMode disk; };
        }
        home-manager.nixosModules.home-manager
        {
          home-manager.useUserPackages = true;
          home-manager.useGlobalPkgs = true;
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = defaultHomeArgs // { isServer = true; };
          home-manager.users.joni = {
            imports = [ ./home/joni.nix ];
          };
        }
      ] ++ extraModules;
    };
  in {

    # --- Custom installer ISO (flash to USB, boots with sshd + SSH keys) ---
    # Build: nix build .#images.worker-iso
    images.worker-iso = (nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./hosts/worker/iso.nix ];
    }).config.system.build.isoImage;

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
          # microvm.nixosModules.host  # Disabled — re-enable when using MicroVM workers
          nixvirt.nixosModules.default

          # Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = defaultHomeArgs // {
              plasmaEnabled = true;
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
            home-manager.extraSpecialArgs = defaultHomeArgs // { isServer = true; };
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
            home-manager.extraSpecialArgs = defaultHomeArgs // {
              plasmaEnabled = true;
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

      # --- k3s worker nodes (shared config) ---
      node5  = mkWorker "node5" {};
      node6  = mkWorker "node6" { bootMode = "uefi"; };
      node9  = mkWorker "node9" {};
      node12 = mkWorker "node12" {};

      # --- NixOS Configuration for ThinkPad X250 (laptop) ---
      x250 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixosRevisionModule

          # Core modules
          ./modules/core

          # Host-specific configuration
          ./hosts/x250/configuration.nix
          ./hosts/x250/hardware.nix

          # Home Manager with Plasma
          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = defaultHomeArgs // {
              plasmaEnabled = true;
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
            home-manager.extraSpecialArgs = defaultHomeArgs // {
              isLinux = false;
              isDarwin = true;
            };
            home-manager.users.joni = { imports = [ ./home/joni.nix ]; };
          }
        ];
      };
    };

    # --- Standalone Home Manager for OnePlus 6T (postmarketOS) ---
    homeConfigurations.oneplus6t = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs { system = "aarch64-linux"; };
      extraSpecialArgs = defaultHomeArgs // {
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
            extraSpecialArgs = defaultHomeArgs // {
              isAndroid = true;
            };
            config = ./home/joni.nix;
          };
        }
      ];
    };
  };
}
