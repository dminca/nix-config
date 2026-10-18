{ lib, pkgs, ... }:
{
  plugins.leetcode = {
    enable = true;
    settings.lang = "python3";
    package = pkgs.vimPlugins.leetcode-nvim.overrideAttrs (oa: {
      src = pkgs.fetchFromGitHub {
        inherit (lib.importJSON ./leetcode-nvim.pin.json)
          owner
          repo
          rev
          hash
          ;
      };
    });
  };
}
