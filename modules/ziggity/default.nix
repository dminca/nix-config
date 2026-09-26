{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homelab.ziggity;
in
{
  options.homelab.ziggity = {
    enable = lib.mkEnableOption "ziggity CLI (https://github.com/simoarpe/ziggity)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../../pkgs/ziggity { };
      description = "ziggity package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
