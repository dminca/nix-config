{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.profiles.desktop.cinnamon;
  lockCommand = pkgs.writeShellScriptBin "cinnamon-lock" ''
    exec ${lib.getExe' pkgs.cinnamon-screensaver "cinnamon-screensaver-command"} -l
  '';
in
{
  options.profiles.desktop.cinnamon.enable = lib.mkEnableOption "Cinnamon user session configuration";

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      XDG_SESSION_TYPE = "x11";
      XDG_CURRENT_DESKTOP = "X-Cinnamon";
      XDG_SESSION_DESKTOP = "cinnamon";
    };

    dconf.settings = {
      "org/cinnamon/desktop/interface" = {
        clock-use-24h = true;
        clock-show-date = true;
        clock-show-seconds = true;
        first-day-of-week = 1;
      };

      "org/cinnamon/desktop/screensaver" = {
        use-custom-format = true;
        date-format = "%a, %d %b. %y";
        time-format = "%H:%M:%S";
      };
    };

    home.packages = [ lockCommand ];
  };
}
