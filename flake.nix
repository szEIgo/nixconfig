# ./flake.nix
{
  description = "Joni's NixOS and macOS Configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      # This makes the repo root available to all modules, so you can use
      # consistent paths like `${root}/nixos/modules` instead of `../../`.
      specialArgs = { root = ./.; };
    in
    {
      # --- NixOS Configurations for Mothership ---
      nixosConfigurations = {
        # This is the base headless system. You can boot into this for maintenance.
        mothership = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          inherit specialArgs;
          modules = [ ./nixos/hosts/mothership/default.nix ];
        };

        # These are your bootable desktop environments, inheriting from the base.
        mothership-amd = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          inherit specialArgs;
          modules = [ ./nixos/hosts/mothership/amd.nix ];
        };
        mothership-nvidia = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          inherit specialArgs;
          modules = [ ./nixos/hosts/mothership/nvidia.nix ];
        };
        mothership-dual-gpu = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          inherit specialArgs;
          modules = [ ./nixos/hosts/mothership/dual-gpu.nix ];
        };
      };

      # --- Home Manager Configurations ---
      homeConfigurations = {
        # Home Manager is applied to a NixOS host via the nixos module,
        # but we define it here for standalone use or other non-NixOS systems.
        "joni@mothership" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = specialArgs;
          modules = [
            ./home-manager/joni.nix
            ./home-manager/modules/plasma.nix # Plasma dotfiles for mothership
          ];
        };

        "joni@jsz-mac-01.nine.dk" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          extraSpecialArgs = specialArgs;
          modules = [
            ./home-manager/joni.nix
            # Specific settings for macOS
            {
              home.username = "joni";
              home.homeDirectory = "/Users/joni";
            }
          ];
        };
      };
    };
}
