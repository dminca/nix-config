{
  config,
  lib,
  ...
}:
let
  cfg = config.maintenance.selfcare;
in
{
  options.maintenance = {
    selfcare = {
      enable = lib.mkEnableOption "Maintenance tasks that permit the host to take care of itself";
    };
  };
  config = lib.mkIf cfg.enable (
    {
      nix = {
        optimise = {
          automatic = true;
          dates = ["02:45"];
        };
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 9d";
        };
      };
    }
  );
}
