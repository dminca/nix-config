{ pkgs, config, lib, ... }:

(final: prev: {
  kluctl = prev.kluctl.override {
    buildGoModule = previousArgs: let self = prev.buildGoModule (previousArgs // {
      version = "2.25.0";
      src = prev.fetchFromGitHub {
        owner = "kluctl";
        repo = "kluctl";
        rev = "refs/tags/v${self.version}";
        hash = "sha256-WtTBkc9mop+bfMcVLI8k4Bqmift5JG9riF+QbDeiR9c=";
        };
    }); in self;
  };
})

