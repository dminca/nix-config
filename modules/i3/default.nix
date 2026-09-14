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
    services.xserver = {
      xkb = {
        layout = "us,ro";
        variant = ",std";
        options = "caps:escape";
      };
      autoRepeatDelay = 233;
      autoRepeatInterval = 17;
    };
    console.useXkbConfig = true;
    services.xserver.windowManager.i3.enable = true;
    services.displayManager.defaultSession = "none+i3";
    security.pam.services.i3lock = {
      fprintAuth = true;
      unixAuth = true;
    };

    home-manager.users.${cfg.user}.profiles.desktop.i3.enable = true;
  };
}
