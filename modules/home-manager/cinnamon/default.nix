{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.profiles.desktop.cinnamon;
  calendarFormat = "%a, %d %b. %y  %H:%M:%S";
  lockCommand = pkgs.writeShellScriptBin "cinnamon-lock" ''
    exec ${lib.getExe' pkgs.cinnamon-screensaver "cinnamon-screensaver-command"} -l
  '';
  syncCalendarFormat = pkgs.writeShellApplication {
    name = "cinnamon-sync-calendar-format";
    runtimeInputs = with pkgs; [ jq ];
    text = ''
      set -euo pipefail

      for path in \
        "$HOME/.config/cinnamon/spices/calendar@cinnamon.org/"*.json \
        "$HOME/.cinnamon/configs/calendar@cinnamon.org/"*.json; do
        [ -f "$path" ] || continue
        tmp="$(mktemp)"
        jq \
          --arg fmt "${calendarFormat}" \
          '
            ."use-custom-format".value = true |
            ."custom-format".value = $fmt |
            ."custom-tooltip-format".value = $fmt
          ' \
          "$path" > "$tmp"
        mv "$tmp" "$path"
      done
    '';
  };
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
      "org/cinnamon" = {
        hotcorner-layout = [
          "cinnamon-lock:true:0"
          "scale:false:0"
          "scale:false:0"
          "desktop:false:0"
        ];
      };

      "org/cinnamon/desktop/interface" = {
        clock-use-24h = true;
        clock-show-date = true;
        clock-show-seconds = true;
        first-day-of-week = 1;
      };

      "org/cinnamon/gestures" = {
        enabled = true;
      };

      "org/cinnamon/desktop/peripherals/keyboard" = {
        repeat = true;
        delay = lib.hm.gvariant.mkUint32 233;
        repeat-interval = lib.hm.gvariant.mkUint32 17;
      };

      "org/cinnamon/desktop/screensaver" = {
        use-custom-format = true;
        date-format = "%a, %d %b. %y";
        time-format = "%H:%M:%S";
      };
    };

    home.activation.cinnamonCalendarFormat = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${lib.getExe syncCalendarFormat}
    '';

    systemd.user.services.cinnamon-calendar-format = {
      Unit = {
        Description = "Apply Cinnamon calendar applet time format";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${lib.getExe syncCalendarFormat}";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    systemd.user.services.touchegg = {
      Unit = {
        Description = "Touchegg gesture daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${lib.getExe pkgs.touchegg}";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    home.packages = [
      lockCommand
      pkgs.touchegg
    ];
  };
}
