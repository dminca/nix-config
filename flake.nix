{
  description = "Daniel personal workstation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    bramble-src = {
      url = "github:flythenimbus/bramble";
      flake = false;
    };
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nixpkgs-unstable,
      bramble-src,
      home-manager,
      sops-nix,
      disko,
      nixos-hardware,
      ...
    }:
    let
      brambleOverlay = final: _prev: {
        bramble =
          let
            unstablePkgs = nixpkgs-unstable.legacyPackages.${final.system};
            trayLibraryPath = unstablePkgs.lib.makeLibraryPath [ unstablePkgs.libayatana-appindicator ];
          in
          (unstablePkgs.callPackage (bramble-src + "/packages/platform-desktop/nix/package.nix") {
            src = bramble-src;
            fetchPnpmDeps = args: unstablePkgs.fetchPnpmDeps (
              args
              // {
                hash = "sha256-j+4xK7MlJQdtmlGOijAn3LWoK4rFPmACK/rDzYJZ8eo=";
              }
            );
          }).overrideAttrs (old: {
            preFixup = (old.preFixup or "") + ''
              gappsWrapperArgs+=(
                --prefix LD_LIBRARY_PATH : ${trayLibraryPath}
              )
            '';
          });
      };

      # ========================================================================
      # HELPER: mkNixosHost
      # ========================================================================
      # Creates a NixOS system configuration with standardized module setup.
      #
      # Args:
      #   - hostname: name of the host (matches ./hosts/${hostname}/ directory)
      #   - system: architecture ("x86_64-linux", "aarch64-linux", etc.)
      #   - hasHardwareConfig: whether to include hardware-configuration.nix
      #   - useDisko: whether to include disko for disk partitioning (default: true)
      #   - extraModules: additional modules to append (default: [])
      #
      # Note: rp-nixos-01 has hasHardwareConfig=false and useDisko=false because
      # it's an LXC container host (no hardware config needed).
      mkNixosHost =
        {
          hostname,
          system,
          hasHardwareConfig ? true,
          useDisko ? true,
          extraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/${hostname}/configuration.nix
          ]
          ++ (if hasHardwareConfig then [ ./hosts/${hostname}/hardware-configuration.nix ] else [ ])
          ++ [
            ./modules
            sops-nix.nixosModules.sops
          ]
          ++ (if useDisko then [ disko.nixosModules.disko ] else [ ])
          ++ extraModules;
        };

      # ========================================================================
      # HELPER: mkDarwinHomeConfig
      # ========================================================================
      # Creates a home-manager configuration for nix-darwin systems.
      mkDarwinHomeConfig =
        hostname:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { system = "aarch64-darwin"; };
          extraSpecialArgs = { inherit inputs; };
          modules = [
            sops-nix.homeManagerModules.sops
            ./modules/home-manager
            ./hosts/common
            ./hosts/${hostname}
          ];
        };

      # ========================================================================
      # HOST DECLARATIONS
      # ========================================================================
      # Declarative registry of all NixOS hosts.
      nixosHosts = {
        nc-nixos-01 = {
          system = "x86_64-linux";
        };
        kc-nixos-01 = {
          system = "x86_64-linux";
        };
        # rp-nixos-01: LXC container host. No hardware config or disko needed.
        rp-nixos-01 = {
          system = "x86_64-linux";
          hasHardwareConfig = false;
          useDisko = false;
        };
        lw-nixos-01 = {
          system = "x86_64-linux";
        };
        ic-nixos-01 = {
          system = "x86_64-linux";
        };
        mon-nixos-01 = {
          system = "x86_64-linux";
        };
        notes-nixos-01 = {
          system = "x86_64-linux";
        };
        rss-nixos-01 = {
          system = "x86_64-linux";
        };
        hs-nixos-01 = {
          system = "x86_64-linux";
          extraModules = [ (nixpkgs-unstable + "/nixos/modules/services/web-apps/hister.nix") ];
        };
        hephaestus = {
          system = "x86_64-linux";
          extraModules = [
            nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
            home-manager.nixosModules.home-manager
            {
              home-manager.sharedModules = [
                sops-nix.homeManagerModules.sops
                ./modules/home-manager
              ];
            }
          ];
        };
      };

      darwinHosts = [
        "ZionProxy"
        "MLGERHL6W4P2RXH"
      ];
    in
    {
      overlays.default = brambleOverlay;

      darwinConfigurations = builtins.listToAttrs (
        map (hostname: {
          name = hostname;
          value = nix-darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            modules = [
              ./hosts/common/system.nix
              ./hosts/${hostname}/system.nix
            ];
          };
        }) darwinHosts
      );

      nixosConfigurations = builtins.mapAttrs (
        hostname: cfg: mkNixosHost ({ inherit hostname; } // cfg)
      ) nixosHosts;

      homeConfigurations = builtins.listToAttrs (
        map (hostname: {
          name = hostname;
          value = mkDarwinHomeConfig hostname;
        }) darwinHosts
      );

      # ========================================================================
      # FLAKE CHECKS
      # ========================================================================
      checks = {
        x86_64-linux = {
          # Validate one NixOS config
          flake-check = self.nixosConfigurations."nc-nixos-01".config.system.build.toplevel;
        };
        aarch64-darwin = {
          # Validate one Darwin config
          flake-check = self.darwinConfigurations."ZionProxy".system;
        };
      };

      # ========================================================================
      # FORMATTERS
      # ========================================================================
      formatter = {
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt;
      };

      # ========================================================================
      # DEVELOPMENT SHELL
      # ========================================================================
      devShells = {
        x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
          buildInputs = with nixpkgs.legacyPackages.x86_64-linux; [
            sops
            age
            nixfmt
            just
          ];
          SOPS_EDITOR = "nvim";
        };
        aarch64-darwin.default = nixpkgs.legacyPackages.aarch64-darwin.mkShell {
          buildInputs = with nixpkgs.legacyPackages.aarch64-darwin; [
            sops
            age
            nixfmt
          ];
          SOPS_EDITOR = "nvim";
        };
      };
    };
}
