{
  description = "Daniel personal workstation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nix-darwin, nixpkgs, home-manager, sops-nix, determinate }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
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
        "nixos" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/common/nixos-system.nix
            ./hosts/nixos/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.dminca = import ./hosts/nixos/default.nix;
              home-manager.extraSpecialArgs = { inherit sops-nix; };
            }
            determinate.nixosModules.default
          ];
          specialArgs = { inherit sops-nix; };
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
    in
    {
      inherit darwinConfigurations nixosConfigurations homeConfigurations;

      apps = forAllSystems (system: 
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = {
            type = "app";
            program = toString (pkgs.writeShellScript "apply-config" ''
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
            '');
          };
        });
    };
}
