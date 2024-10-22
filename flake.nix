{
  description = "Daniel personal workstation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nix-darwin,
    nixpkgs,
    home-manager,
    sops-nix
  }:
  {
    darwinConfigurations = {
      "ne0byte" = nix-darwin.lib.darwinSystem {
        modules = [
          ./hosts/common/system.nix
          ./hosts/MacbookAir.fritz.box/system.nix
        ];
      };

      "M-C02FX3JUML85" = nix-darwin.lib.darwinSystem {
        modules = [
          ./hosts/common/system.nix
          ./hosts/M-C02FX3JUML85/system.nix
        ];
      };
    };

    defaultPackage.aarch64-darwin = home-manager.defaultPackage.aarch64-darwin;
    defaultPackage.x86_64-darwin = home-manager.defaultPackage.x86_64-darwin;
    homeConfigurations = {
      "dminca" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
        };
        modules = [
          sops-nix.homeManagerModules.sops
          ./hosts/common
          ./hosts/MacbookAir.fritz.box
        ];
      };

      "DanielAndrei.Minca" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-darwin";
          overlays = [
            (builtins.trace "Importing overlay" (import ./overlays/kluctl))
          ];
        };
        modules = [
          sops-nix.homeManagerModules.sops
          ./hosts/common
          ./hosts/M-C02FX3JUML85
        ];
      };
    };
  };
}
