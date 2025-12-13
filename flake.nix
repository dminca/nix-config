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
      packages = forAllSystems (system: 
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = 
            if pkgs.stdenv.isDarwin then
              # Darwin/macOS script
              pkgs.writeShellScriptBin "apply-configurations" ''
                HOSTNAME=$(scutil --get ComputerName || hostname)

                case "$HOSTNAME" in
                  "ZionProxy")
                    sudo darwin-rebuild switch --flake .#ZionProxy &&
                    home-manager switch --flake .#dminca
                    ;;
                  "MLGERHL6W4P2RXH")
                    sudo darwin-rebuild switch --flake .#MLGERHL6W4P2RXH &&
                    home-manager switch --flake .#mida4001
                    ;;
                  *)
                    echo "Unknown host: $HOSTNAME"
                    echo "Available configurations: ZionProxy, MLGERHL6W4P2RXH"
                    exit 1
                    ;;
                esac
              ''
            else
              # NixOS/Linux script
              pkgs.writeShellScriptBin "apply-nixos-configuration" ''
                HOSTNAME=$(hostname)
                case "$HOSTNAME" in
                  "nixos")
                    sudo nixos-rebuild switch --flake .#nixos
                    ;;
                  "nixos-fake")
                    sudo nixos-rebuild switch --flake .#nixos-desktop
                    ;;
                  *)
                    echo "Unknown hostname: $HOSTNAME"
                    echo "Available configurations: nixos, nixos-fake"
                    exit 1
                    ;;
                esac
              '';
        });
    };
}

