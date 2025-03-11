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
      "ne0byte" = nix-darwin.lib.darwinSystem {
        modules = [
          ./hosts/common/system.nix
          ./hosts/MacbookAir.fritz.box/system.nix
        ];
      };

      "MLGERC02FX3JUML85" = nix-darwin.lib.darwinSystem {
        modules = [
          ./hosts/common/system.nix
          ./hosts/MLGERC02FX3JUML85/system.nix
        ];
      };
    };

    homeConfigurations = {
      "dminca" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "aarch64-darwin"; };
        modules = [
          sops-nix.homeManagerModules.sops
          ./hosts/common
          ./hosts/MacbookAir.fritz.box
        ];
      };

      "mida4001" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-darwin"; };
        modules = [
          sops-nix.homeManagerModules.sops
          ./hosts/common
          ./hosts/MLGERC02FX3JUML85
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
      ${darwinConfigurations.ne0byte.config.system.build.toplevel}/sw/bin/darwin-rebuild switch --flake . &&
      ${homeConfigurations.dminca.activationPackage}/activate
    '';

    packages.x86_64-darwin.default = let
      pkgs = import nixpkgs { system = "x86_64-darwin"; };
    in pkgs.writeShellScriptBin "apply-configurations" ''
      ${darwinConfigurations.MLGERC02FX3JUML85.config.system.build.toplevel}/sw/bin/darwin-rebuild switch --flake . &&
      ${homeConfigurations."mida4001".activationPackage}/activate
    '';
  };
}

