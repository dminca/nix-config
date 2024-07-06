{ pkgs, config, lib, ... }:

(final: prev: {
  kluctl = prev.kluctl.override {
    buildGoModule = previousArgs: prev.buildGoModule (previousArgs // rec {
      version = "2.25.0";
      src = prev.fetchFromGitHub {
        owner = "kluctl";
        repo = "kluctl";
        rev = "refs/tags/v${version}";
        hash = "";
        };
    });
  };
})

