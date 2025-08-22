{
  description = "Daniel personal workstation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgsBlenderPinned = {
      # FIXME(blender): remove this once fixed upstream
      url = "github:NixOS/nixpkgs/fa0ef8a6bb1651aa26c939aeb51b5f499e86b0ec";
    };
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

  outputs = { self, nix-darwin, nixpkgs, home-manager, sops-nix, determinate, nixpkgsBlenderPinned }:
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
          extraSpecialArgs = { inherit nixpkgsBlenderPinned; };
        };

        "mida4001" = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { system = "aarch64-darwin"; };
          modules = [
            sops-nix.homeManagerModules.sops
            ./hosts/common
            ./hosts/MLGERHL6W4P2RXH
          ];
          extraSpecialArgs = { inherit nixpkgsBlenderPinned; };
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

                if [ "$HOSTNAME" = "ZionProxy" ]; then
                  sudo ${darwinConfigurations.ZionProxy.config.system.build.toplevel}/sw/bin/darwin-rebuild switch --flake . &&
                  ${homeConfigurations.dminca.activationPackage}/activate
                elif [ "$HOSTNAME" = "MLGERHL6W4P2RXH" ]; then
                  sudo ${darwinConfigurations.MLGERHL6W4P2RXH.config.system.build.toplevel}/sw/bin/darwin-rebuild switch --flake . &&
                  ${homeConfigurations.mida4001.activationPackage}/activate
                else
                  echo "Unknown host: $HOSTNAME"
                  exit 1
                fi
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

