{ pkgs, config, lib, ... }:

(self: super: {
  kluctl = super.kluctl.override {
    version = "2.25.0";
  };
})
