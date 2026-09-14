{
  config,
  lib,
  ...
}:
let
  cfg = config.profiles.desktop.i3;
in
{
  options.profiles.desktop.i3 = {
    enable = lib.mkEnableOption "i3 desktop profile";

    user = lib.mkOption {
      type = lib.types.str;
      default = "dminca";
      description = "Home Manager user that receives i3 session configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver.windowManager.i3.enable = true;
    services.displayManager.defaultSession = "none+i3";

    home-manager.users.${cfg.user}.profiles.desktop.i3.enable = true;
  };
}
