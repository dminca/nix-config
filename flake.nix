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

    # TODO: are these still needed?
    #darwinPackages = self.darwinConfigurations."ne0byte".pkgs;
    #darwinPackages = self.darwinConfigurations."M-C02FX3JUML85".pkgs;

    defaultPackage.aarch64-darwin = home-manager.defaultPackage.aarch64-darwin;
    defaultPackage.x86_64-darwin = home-manager.defaultPackage.x86_64-darwin;
    homeConfigurations = {
      "dminca" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "aarch64-darwin"; };
        modules = [
          sops-nix.homeManagerModules.sops
          ./hosts/MacbookAir.fritz.box/home.nix
          ./hosts/common/neovim.nix
          ./hosts/MacbookAir.fritz.box/vim.nix
          ./hosts/common/git.nix
          ./hosts/MacbookAir.fritz.box/git.nix
          ./hosts/MacbookAir.fritz.box/zshrc.nix
        ];
      };

      "DanielAndrei.Minca" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-darwin"; };
        modules = [
          sops-nix.homeManagerModules.sops
          ./hosts/M-C02FX3JUML85/home-manager/home.nix
          ./hosts/M-C02FX3JUML85/home-manager/zshrc.nix
          ./hosts/common/neovim.nix
          ./hosts/M-C02FX3JUML85/home-manager/neovim.nix
          ./hosts/common/git.nix
          ./hosts/M-C02FX3JUML85/home-manager/git.nix
        ];
      };
    };
  };
}
