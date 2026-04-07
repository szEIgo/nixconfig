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

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    impermanence.url = "github:nix-community/impermanence";

    nix-topology.url = "github:oddlama/nix-topology";
    nix-topology.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, sops-nix, nixvirt, microvm, plasma-manager, nix-on-droid, disko, deploy-rs, nixos-hardware, impermanence, nix-topology, ... }:
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

    # Helper to create k3s nodes (workers or servers)
    # bootMode: "legacy" (BIOS/GRUB) or "uefi" (GPT/systemd-boot)
    # k3sRole: "agent" (worker) or "server" (control plane)
    # nodeSize: "small", "medium", or "large" — used for scheduling labels
    mkWorker = hostname: { bootMode ? "legacy", disk ? "/dev/sda", k3sRole ? "agent", nodeSize ? "small", keepalivedPriority ? 100, keepalivedInterface ? "enp0s31f6", extraModules ? [] }: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixosRevisionModule
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        impermanence.nixosModules.impermanence
        nix-topology.nixosModules.default
        ./modules/core
        ./hosts/worker/disko.nix
        ./hosts/worker/configuration.nix
        ./hosts/worker/hardware.nix
        ./secrets/worker.nix
        {
          networking.hostName = hostname;
          local.worker = { inherit bootMode disk k3sRole nodeSize keepalivedPriority keepalivedInterface; };
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
          nix-topology.nixosModules.default

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


      # --- NixOS Configuration for ThinkPad T480 (laptop) ---
      t480 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixosRevisionModule
          nixos-hardware.nixosModules.lenovo-thinkpad-t480
          nix-topology.nixosModules.default

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

      # --- k3s carrier nodes (control plane) ---
      carrier-tc1 = mkWorker "carrier-tc1" { bootMode = "uefi"; k3sRole = "server"; nodeSize = "medium"; keepalivedPriority = 150; keepalivedInterface = "enp2s0"; extraModules = [
        ./hosts/worker/misi.nix
        home-manager.nixosModules.home-manager
        { home-manager.users.misi = { imports = [ ./home/misi/default.nix ]; }; }
      ]; };
      carrier-tc2 = mkWorker "carrier-tc2" { k3sRole = "server"; nodeSize = "medium"; keepalivedPriority = 140; keepalivedInterface = "enp2s0"; };

      # --- k3s interceptor nodes (workers) ---
      interceptor-nuc1 = mkWorker "interceptor-nuc1" { bootMode = "uefi"; disk = "/dev/nvme0n1"; nodeSize = "medium"; extraModules = [ nixos-hardware.nixosModules.intel-nuc-5i5ryb ]; };
      interceptor-tc1  = mkWorker "interceptor-tc1" { nodeSize = "small"; };
      interceptor-tc2  = mkWorker "interceptor-tc2" { nodeSize = "small"; };

      # --- NixOS Configuration for ThinkPad X250 (laptop) ---
      x250 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixosRevisionModule
          nixos-hardware.nixosModules.lenovo-thinkpad-x250
          nix-topology.nixosModules.default

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

    # --- deploy-rs: remote deployment with automatic rollback ---
    deploy = {
      sshUser = "root";
      # Magic rollback: if the node loses connectivity after activation,
      # it reverts to the previous generation after this timeout (seconds)
      magicRollback = true;

      nodes = let
        mkDeployNode = hostname: ip: {
          hostname = ip;
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.${hostname};
          };
        };
      in {
        carrier-tc1      = mkDeployNode "carrier-tc1"      "192.168.2.192";
        carrier-tc2      = mkDeployNode "carrier-tc2"      "192.168.2.250";
        interceptor-nuc1 = mkDeployNode "interceptor-nuc1" "192.168.2.102";
        interceptor-tc1  = mkDeployNode "interceptor-tc1"  "192.168.2.238";
        interceptor-tc2  = mkDeployNode "interceptor-tc2"  "192.168.2.147";
      };
    };

    # deploy-rs validation checks
    checks = builtins.mapAttrs
      (system: deployLib: deployLib.deployChecks self.deploy)
      deploy-rs.lib;

    # Network topology diagram — build with: nix build .#topology.x86_64-linux.config.output
    topology.x86_64-linux = import nix-topology {
      pkgs = import nixpkgs { system = "x86_64-linux"; overlays = [ nix-topology.overlays.default ]; };
      modules = [
        ./topology.nix
        { inherit (self) nixosConfigurations; }
      ];
    };
  };
}
