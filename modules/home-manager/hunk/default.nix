{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.profiles.common.hunk;
  unstablePkgs = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
  };
  hunk = unstablePkgs.hunk;
in
{
  options.profiles.common.hunk.enable = lib.mkEnableOption "Hunk as the default Git difftool";

  config = lib.mkIf cfg.enable {
    home.packages = [ hunk ];
    programs.git = {
      enable = true;
      settings = {
        diff.tool = "hunk";
        difftool = {
          prompt = false;
          hunk.cmd = ''${lib.getExe hunk} difftool "$LOCAL" "$REMOTE" "$MERGED"'';
        };
      };
    };
  };
}
