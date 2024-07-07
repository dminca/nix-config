{ pkgs, config, lib, ... }:

(final: prev: {
  kluctl = prev.kluctl.override {
    buildGoModule = previousArgs: let self = prev.buildGoModule (previousArgs // {
      version = "2.25.0";
      vendorHash = "sha256-TckT39wQn4dclcYSfxootv1Lw5+iYxY6/wwdUc1+Z6s=";
      src = prev.fetchFromGitHub {
        owner = "kluctl";
        repo = "kluctl";
        rev = "refs/tags/v${self.version}";
        hash = "sha256-WtTBkc9mop+bfMcVLI8k4Bqmift5JG9riF+QbDeiR9c=";
        };
    }); in self;
  };
})

