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

  outputs = { self, nix-darwin, nixpkgs, home-manager, sops-nix }:
    let
      configuration = { pkgs, ... }: {
        environment.systemPackages = [ pkgs.neovim ];

        services.nix-daemon.enable = true;
        nix.settings.experimental-features = "nix-command flakes";
        programs.zsh.enable = true;

        system.configurationRevision = self.rev or self.dirtyRev or null;
        system.stateVersion = 4;
        system.keyboard.enableKeyMapping = true;
        system.keyboard.remapCapsLockToEscape = true;
        system.defaults.NSGlobalDomain.InitialKeyRepeat = 14;
        system.defaults.NSGlobalDomain.KeyRepeat = 1;
        nixpkgs.hostPlatform = "aarch64-darwin";
      };
    in
    {
      darwinConfigurations."ne0byte" = nix-darwin.lib.darwinSystem {
        modules = [ configuration ];
      };

      darwinPackages = self.darwinConfigurations."ne0byte".pkgs;

      defaultPackage.aarch64-darwin = home-manager.defaultPackage.aarch64-darwin;
      homeConfigurations = {
        "dminca" = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { system = "aarch64-darwin"; };
          modules = [
            sops-nix.homeManagerModules.sops
            ./home.nix
            ./vim.nix
            ./git.nix
            ./zshrc.nix
          ];
        };
      };
    };
}
