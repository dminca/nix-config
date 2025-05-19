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

  outputs = { self, nix-darwin, nixpkgs, home-manager, sops-nix }: let
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
  in {
    # Expose darwinConfigurations and homeConfigurations
    inherit darwinConfigurations homeConfigurations;

    # Define packages for `nix build`
    packages.aarch64-darwin.default = let
      pkgs = import nixpkgs { system = "aarch64-darwin"; };
    in pkgs.writeShellScriptBin "apply-configurations" ''
      ${darwinConfigurations.ZionProxy.config.system.build.toplevel}/sw/bin/darwin-rebuild switch --flake . &&
      ${homeConfigurations.dminca.activationPackage}/activate
    '';

    packages.aarch64-darwin.default = let
      pkgs = import nixpkgs { system = "aarch64-darwin"; };
    in pkgs.writeShellScriptBin "apply-configurations" ''
      ${darwinConfigurations.MLGERHL6W4P2RXH.config.system.build.toplevel}/sw/bin/darwin-rebuild switch --flake . &&
      ${homeConfigurations."mida4001".activationPackage}/activate
    '';
  };
}

