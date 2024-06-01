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
    system.configurationRevision = self.rev or self.dirtyRev or null;
    darwinConfigurations = {
      "ne0byte" = nix-darwin.lib.darwinSystem {
        modules = [
          ./hosts/MacbookAir.fritz.box/system.nix
        ];
      };
    };

    darwinPackages = self.darwinConfigurations."ne0byte".pkgs;

    defaultPackage.aarch64-darwin = home-manager.defaultPackage.aarch64-darwin;
    defaultPackage.x86_64-darwin = home-manager.defaultPackage.x86_64-darwin;
    homeConfigurations = {
      "dminca" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "aarch64-darwin"; };
        modules = [
          sops-nix.homeManagerModules.sops
          ./hosts/MacbookAir.fritz.box/home.nix
          ./hosts/MacbookAir.fritz.box/vim.nix
          ./hosts/MacbookAir.fritz.box/git.nix
          ./hosts/MacbookAir.fritz.box/zshrc.nix
        ];
      };
    };
  };
}
