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

  outputs = { self, nix-darwin, nixpkgs, home-manager, sops-nix, inputs }:
    let
      # Define darwinConfigurations first
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
      # Expose darwinConfigurations and homeConfigurations
      inherit darwinConfigurations homeConfigurations;

      # Define packages for `nix build`
      packages.aarch64-darwin.default =
        let
          pkgs = import nixpkgs { 
            system = "aarch64-darwin";
            overlays = [
              # Add nh to the package set
              (final: prev: {
                nh = inputs.nh.packages.aarch64-darwin.default;
              })
            ];
          };
        in
        pkgs.writeShellScriptBin "apply-configurations" ''
          USERNAME=$(whoami)

          if [ "$USERNAME" = "dminca" ]; then
            ${pkgs.nh}/bin/nh os switch --hostname ZionProxy . &&
            ${pkgs.nh}/bin/nh home switch --configuration dminca .
          elif [ "$USERNAME" = "mida4001" ]; then
            ${pkgs.nh}/bin/nh os switch --hostname MLGERHL6W4P2RXH . &&
            ${pkgs.nh}/bin/nh home switch --configuration mida4001 .
          else
            echo "Unknown user: $USERNAME"
            exit 1
          fi
        '';
    };
}

