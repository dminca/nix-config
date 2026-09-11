{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.profiles.desktop.polybar;
  layoutToggleScript = pkgs.writeShellScriptBin "toggle-layout" ''
    # Get current layout
    CURRENT=$(${lib.getExe pkgs.xkb-switch} -p)

    # Toggle between us and ro
    if [ "$CURRENT" = "us" ]; then
      ${lib.getExe pkgs.xkb-switch} -s ro
    else
      ${lib.getExe pkgs.xkb-switch} -s us
    fi
  '';

  layoutIndicatorScript = pkgs.writeShellScriptBin "layout-indicator" ''
    LAYOUT=$(${lib.getExe pkgs.xkb-switch} -p)

    case "$LAYOUT" in
      us)
        echo "🇺🇸 US"
        ;;
      ro)
        echo "🇷🇴 RO"
        ;;
      *)
        echo "$LAYOUT"
        ;;
    esac
  '';
in
{
  options.profiles.desktop.polybar = {
    enable = lib.mkEnableOption "Polybar status bar";

    position = lib.mkOption {
      type = lib.types.enum [ "top" "bottom" ];
      default = "top";
      description = "Position of the polybar";
    };

    height = lib.mkOption {
      type = lib.types.int;
      default = 28;
      description = "Height of the polybar in pixels";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      polybar
      xkb-switch
      xclip
      jq
      curl
      noto-fonts-color-emoji
    ];

    home.file.".config/polybar/config.ini".text = ''
      [colors]
      background = #1e1e1e
      foreground = #ffffff
      primary = #7aa2f7
      alert = #ff6b6b
      disabled = #666666
      success = #9ece6a

      [bar/main]
      monitor = ''${env:MONITOR:}
      width = 100%
      height = ${toString cfg.height}
      offset-y = 0
      offset-x = 0
      position = ${cfg.position}
      fixed-center = true
      background = ''${colors.background}
      foreground = ''${colors.foreground}
      border-size = 0
      line-size = 3pt
      padding-left = 2
      padding-right = 2
      module-margin = 1
      separator = " | "
      font-0 = "JetBrains Mono:style=Regular:size=11;3"
      font-1 = "Noto Color Emoji:style=Regular:size=11;3"
      modules-left = i3 xwindow
      modules-center = clock
      modules-right = layout volume battery network cpu memory tray
      cursor-click = pointer

      [module/i3]
      type = internal/i3
      format = <label-state> <label-mode>
      index-sort = true
      wrapping-scroll = false
      label-mode-padding = 2
      label-mode-foreground = ''${colors.background}
      label-mode-background = ''${colors.primary}
      label-focused = %index%
      label-focused-background = ''${colors.primary}
      label-focused-foreground = ''${colors.background}
      label-focused-padding = 2
      label-unfocused = %index%
      label-unfocused-padding = 2
      label-visible = %index%
      label-visible-background = ''${colors.disabled}
      label-visible-padding = 2
      label-urgent = %index%
      label-urgent-background = ''${colors.alert}
      label-urgent-padding = 2

      [module/xwindow]
      type = internal/xwindow
      label = %title:0:50:%

      [module/clock]
      type = internal/date
      interval = 1
      date = %a, %d %b. %y
      time = %H:%M:%S
      format = <label>
      label = 📅 %date% %time%
      label-foreground = ''${colors.primary}

      [module/layout]
      type = custom/script
      exec = ${layoutIndicatorScript}/bin/layout-indicator
      interval = 1
      click-left = ${layoutToggleScript}/bin/toggle-layout
      format = <label>
      label = %output%

      [module/volume]
      type = internal/alsa
      master-soundcard = default
      speaker-soundcard = default
      headphone-soundcard = default
      master-mixer-index = 0
      interval = 5
      format-volume = <ramp-volume> <label-volume>
      format-muted = 🔇 <label-muted>
      label-volume = %percentage%%
      label-muted = muted
      label-muted-foreground = ''${colors.disabled}
      ramp-volume-0 = 🔈
      ramp-volume-1 = 🔉
      ramp-volume-2 = 🔊

      [module/battery]
      type = internal/battery
      battery = BAT0
      adapter = AC0
      poll-interval = 5
      time-format = %H:%M
      format-charging = <animation-charging> <label-charging>
      format-discharging = <ramp-capacity> <label-discharging>
      format-full = <ramp-capacity> <label-full>
      label-charging = %percentage%%
      label-discharging = %percentage%%
      label-full = %percentage%%
      ramp-capacity-0 = 🪫
      ramp-capacity-1 = 🔋
      ramp-capacity-2 = 🔋
      ramp-capacity-3 = 🔋
      ramp-capacity-4 = ⚡
      animation-charging-0 = ⚡
      animation-charging-1 = 🔌
      animation-charging-framerate = 750

      [module/cpu]
      type = internal/cpu
      interval = 1
      format = CPU <label>
      label = %percentage%%
      label-foreground = ''${colors.primary}

      [module/memory]
      type = internal/memory
      interval = 1
      format = RAM <label>
      label = %percentage_used%%
      label-foreground = ''${colors.primary}

      [module/network]
      type = internal/network
      interface = wlan0
      interval = 1.0
      ping-interval = 10
      format-connected = <label-connected>
      format-disconnected = <label-disconnected>
      label-connected = 📡 %local_ip%
      label-disconnected = ❌ No WiFi
      label-disconnected-foreground = ''${colors.disabled}

      [module/tray]
      type = internal/tray
      tray-position = right
      tray-padding = 2
      tray-background = ''${colors.background}
    '';

    systemd.user.services.polybar = {
      Unit = {
        Description = "Polybar status bar";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        Environment = [
          "PATH=${lib.makeBinPath (with pkgs; [ bash coreutils findutils ])}"
        ];
        ExecStart = "${lib.getExe pkgs.polybar} main";
        Restart = "on-failure";
        RestartSec = 3;
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
