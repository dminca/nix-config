# Run with: nix eval --impure --file modules/nvix/tests/module.nix
let
  inputs = (builtins.getFlake (toString ../../..)).inputs;
  mkHome =
    system: extra:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs { inherit system; };
      extraSpecialArgs = { inherit inputs; };
      modules = [
        ../default.nix
        {
          home.username = "test";
          home.homeDirectory = if system == "aarch64-darwin" then "/Users/test" else "/home/test";
          home.stateVersion = "26.05";
          programs.nvix.enable = true;
        }
        extra
      ];
    };
  failed = home: builtins.filter (item: !item.assertion) home.config.assertions;
  legacy = mkHome "aarch64-darwin" { };
  native = mkHome "aarch64-darwin" {
    programs.nvix.backend = "native";
    programs.nvix.servers.marksman = false;
  };
  linux = mkHome "x86_64-linux" { programs.nvix.backend = "native"; };
  incompatible = mkHome "aarch64-darwin" {
    programs.nvix.backend = "native";
    programs.nvix.package = "full";
    programs.nvix.settings.plugins.lsp.enable = false;
  };
  unusedOverrides = mkHome "aarch64-darwin" { programs.nvix.servers.marksman = false; };
in
assert legacy.config.programs.nixvim.enable;
assert !legacy.config.programs.neovim.enable;
assert native.config.programs.neovim.enable;
assert !native.config.programs.nixvim.enable;
assert linux.config.programs.neovim.enable;
assert !linux.config.programs.nixvim.enable;
assert failed native == [ ];
assert failed linux == [ ];
assert builtins.match ".*\"marksman\":false.*" native.config.programs.neovim.initLua != null;
assert !(builtins.tryEval incompatible.config.programs.neovim.enable).success;
assert !(builtins.tryEval unusedOverrides.config.programs.nixvim.enable).success;
"Native and legacy module selection OK"
