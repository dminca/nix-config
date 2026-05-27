{
  description = "Daniel personal workstation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
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
            ./modules/monitoring
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
          ];
        };
        "kc-nixos-01" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/kc-nixos-01/configuration.nix
            ./hosts/kc-nixos-01/hardware-configuration.nix
            ./modules/monitoring
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
          ];
        };
        "rp-nixos-01" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/rp-nixos-01/configuration.nix
            ./modules/monitoring
            sops-nix.nixosModules.sops
          ];
        };
        "hm-nixos-01" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/hm-nixos-01/configuration.nix
            ./hosts/hm-nixos-01/hardware-configuration.nix
            ./modules/monitoring
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
          ];
        };
        "lw-nixos-01" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/lw-nixos-01/configuration.nix
            ./hosts/lw-nixos-01/hardware-configuration.nix
            ./modules/monitoring
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
          ];
        };
        "ic-nixos-01" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/ic-nixos-01/configuration.nix
            ./hosts/ic-nixos-01/hardware-configuration.nix
            ./modules/monitoring
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
          ];
        };
        "mon-nixos-01" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/mon-nixos-01/configuration.nix
            ./hosts/mon-nixos-01/hardware-configuration.nix
            ./modules/monitoring
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
            ./hosts/common
            ./hosts/ZionProxy
          ];
        };

        "mida4001" = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { system = "aarch64-darwin"; };
          modules = [
            sops-nix.homeManagerModules.sops
            ./hosts/common
            ./hosts/MLGERHL6W4P2RXH
          ];
        };
      };

      # Day-0 image artifacts built from ./nixos-generator for Proxmox VM/LXC.
      day0Packages = nixos-generator.packages.x86_64-linux;
    in
    {
      inherit
        darwinConfigurations
        nixosConfigurations
        homeConfigurations
        day0Packages
        ;

      # Expose day-0 generator outputs directly so they can be built with:
      #   nix build .#<host>
      #   nix build .#<host>-plxc
      packages = forAllSystems (_: day0Packages);

      apps = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = {
            type = "app";
            program = toString (
              pkgs.writeShellScript "apply-config" ''
                set -e
                HOSTNAME=$(${pkgs.lib.getExe' pkgs.nettools "hostname"})

                if [[ "$OSTYPE" == "darwin"* ]]; then
                  echo "🍎 Applying configuration for macOS host: $HOSTNAME"
                  ${pkgs.lib.getExe pkgs.nh} darwin switch .
                  ${pkgs.lib.getExe pkgs.nh} home switch .
                else
                  echo "🐧 Applying configuration for NixOS host: $HOSTNAME"
                  ${pkgs.lib.getExe pkgs.nh} os switch .
                fi
              ''
            );
          };
        }
      );
    };
}
