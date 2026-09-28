{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homelab.radicle-backup;
in
{
  options.homelab.radicle-backup = {
    enable = lib.mkEnableOption "radicle-backup CLI";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../../pkgs/radicle-backup { };
      description = "radicle-backup package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
