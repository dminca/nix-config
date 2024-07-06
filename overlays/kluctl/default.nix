{ pkgs, config, lib, ... }:

(self: super: {
  kluctl = super.kluctl.overrideAttrs {
    src = pkgs.fetchFromGitHub {
      owner = "kluctl";
      repo = "kluctl";
      rev = "v2.25.0";
      hash = "";
    };
  };
})
