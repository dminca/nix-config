{
  description = "Daniel personal workstation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-generator = {
      url = "path:./nixos-generator";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvix = {
      url = "github:niksingh710/nvix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      sops-nix,
      disko,
      nixos-generator,
      nvix,
    }:
    {
      darwinConfigurations = {
        "ZionProxy" = nix-darwin.lib.darwinSystem {
          modules = [
            ./hosts/common/system.nix
            ./hosts/ZionProxy/system.nix
          ];
        };

        "MLGERHL6W4P2RXH" = nix-darwin.lib.darwinSystem {
          modules = [
            ./hosts/common/system.nix
            ./hosts/MLGERHL6W4P2RXH/system.nix
          ];
        };
      };
      nixosConfigurations = {
        "nc-nixos-01" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/nc-nixos-01/configuration.nix
            ./hosts/nc-nixos-01/hardware-configuration.nix
            ./modules
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
          ];
        };
        "kc-nixos-01" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/kc-nixos-01/configuration.nix
            ./hosts/kc-nixos-01/hardware-configuration.nix
            ./modules
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
          ];
        };
        "rp-nixos-01" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/rp-nixos-01/configuration.nix
            ./modules
            sops-nix.nixosModules.sops
          ];
        };
        "lw-nixos-01" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/lw-nixos-01/configuration.nix
            ./hosts/lw-nixos-01/hardware-configuration.nix
            ./modules
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
          ];
        };
        "ic-nixos-01" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/ic-nixos-01/configuration.nix
            ./hosts/ic-nixos-01/hardware-configuration.nix
            ./modules
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
          ];
        };
        "mon-nixos-01" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/mon-nixos-01/configuration.nix
            ./hosts/mon-nixos-01/hardware-configuration.nix
            ./modules
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
          ];
        };
      };

      homeConfigurations = {
        "dminca" = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { system = "aarch64-darwin"; };
          modules = [
            sops-nix.homeManagerModules.sops
            ({ pkgs, ... }: {
              home.packages = [
                nvix.packages.${pkgs.stdenv.hostPlatform.system}.default
              ];
            })
            ./hosts/common
            ./hosts/ZionProxy
          ];
        };

        "mida4001" = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { system = "aarch64-darwin"; };
          modules = [
            sops-nix.homeManagerModules.sops
            ({ pkgs, ... }: {
              home.packages = [
                (nvix.packages.${pkgs.stdenv.hostPlatform.system}.default.extend {
                  plugins.codecompanion.enable = false;
                })
              ];
            })
            ./hosts/common
            ./hosts/MLGERHL6W4P2RXH
          ];
        };
      };
    };
}
