{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.profiles.desktop.polybar;

  layoutToggleScript = pkgs.writeShellScriptBin "toggle-layout" ''
    CURRENT=$(${lib.getExe pkgs.xkb-switch} -p)

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
        echo "US"
        ;;
      ro)
        echo "RO"
        ;;
      *)
        echo "$LAYOUT"
        ;;
    esac
  '';

  polybarThemesRev = "7735b96afd72f835c7c909599265fb431886d7c0";
  polybarThemesSrc = pkgs.fetchzip {
    url = "https://github.com/adi1090x/polybar-themes/archive/${polybarThemesRev}.tar.gz";
    hash = "sha256-f/54m7RJnqNW6eC/75IrnFxmSWTY+zd5epm6TQsYeYA=";
  };
  networkInterfaceConfig =
    if cfg.networkInterface == "auto" then
      "interface-type = wireless"
    else
      "interface = ${cfg.networkInterface}";
  diskIoScript = pkgs.writeShellScriptBin "polybar-disk-io" ''
    set -eu

    cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/polybar"
    state_file="$cache_dir/disk-io.state"
    mkdir -p "$cache_dir"

    source_path="$(${lib.getExe' pkgs.util-linux "findmnt"} -no SOURCE /)"
    device="$(${lib.getExe' pkgs.coreutils "readlink"} -f "$source_path")"
    device_name="$(${lib.getExe' pkgs.coreutils "basename"} "$device")"
    now_ns="$(${lib.getExe' pkgs.coreutils "date"} +%s%N)"
    busy_ms="$(${lib.getExe' pkgs.gawk "awk"} -v dev="$device_name" '$3 == dev { print $13; exit }' /proc/diskstats)"

    if [ -z "$busy_ms" ]; then
      echo " N/A"
      exit 0
    fi

    if [ -r "$state_file" ]; then
      read -r old_now_ns old_busy_ms < "$state_file"
      percent="$(${lib.getExe' pkgs.gawk "awk"} -v old_now="$old_now_ns" -v old_busy="$old_busy_ms" -v now="$now_ns" -v busy="$busy_ms" 'BEGIN {
        elapsed_ms = (now - old_now) / 1000000;
        delta_busy = busy - old_busy;
        if (elapsed_ms <= 0 || delta_busy < 0) {
          print "0%"
          exit
        }
        printf "%.0f%%", (delta_busy / elapsed_ms) * 100
      }')"
    else
      percent="0%"
    fi

    printf '%s %s\n' "$now_ns" "$busy_ms" > "$state_file"
    echo " $percent"
  '';

  diskCapacityScript = pkgs.writeShellScriptBin "polybar-disk-capacity" ''
    set -eu

    root_usage="$(${lib.getExe' pkgs.coreutils "df"} -BG --output=avail,size / | ${lib.getExe' pkgs.gawk "awk"} 'NR == 2 {
      avail = $1
      size = $2
      sub(/[^0-9].*/, "", avail)
      sub(/[^0-9].*/, "", size)
      if (size > 0) {
        printf "%.0f%% free / %sG", (avail / size) * 100, size
      } else {
        printf "N/A"
      }
    }')"
    echo "󰆼 $root_usage"
  '';
  forestWallpapers = pkgs.runCommand "polybar-forest-wallpapers" { } ''
    mkdir -p "$out"
    cp -R "${polybarThemesSrc}/wallpapers/." "$out/"
  '';

  wallpaperApplyScript = pkgs.writeShellScriptBin "forest-wallpaper-apply" ''
    set -eu

    current_path="${cfg.wallpaper.currentPath}"
    mkdir -p "$(${lib.getExe' pkgs.coreutils "dirname"} "$current_path")"

    first_wallpaper="$(${lib.getExe pkgs.fd} --absolute-path --type f --extension jpg --extension png . ${forestWallpapers} | ${lib.getExe' pkgs.coreutils "sort"} | ${lib.getExe' pkgs.coreutils "head"} -n 1)"
    if [ -z "$first_wallpaper" ]; then
      echo "No wallpapers available in ${forestWallpapers}" >&2
      exit 1
    fi

    if [ ! -L "$current_path" ] && [ ! -e "$current_path" ]; then
      ${lib.getExe' pkgs.coreutils "ln"} -sfn "$first_wallpaper" "$current_path"
    fi

    target=""
    if [ -L "$current_path" ]; then
      target="$(${lib.getExe' pkgs.coreutils "readlink"} "$current_path")"
    elif [ -f "$current_path" ]; then
      target="$current_path"
    fi

    if [ -z "$target" ] || [ ! -f "$target" ]; then
      target="$first_wallpaper"
      ${lib.getExe' pkgs.coreutils "ln"} -sfn "$target" "$current_path"
    fi

    exec ${lib.getExe pkgs.feh} --bg-fill "$target"
  '';

  wallpaperPickerScript = pkgs.writeShellScriptBin "forest-wallpaper-picker" ''
    set -eu

    current_path="${cfg.wallpaper.currentPath}"
    mkdir -p "$(${lib.getExe' pkgs.coreutils "dirname"} "$current_path")"

    mapfile -t wallpapers < <(${lib.getExe pkgs.fd} --absolute-path --type f --extension jpg --extension png . ${forestWallpapers} | ${lib.getExe' pkgs.coreutils "sort"})
    if [ "''${#wallpapers[@]}" -eq 0 ]; then
      echo "No wallpapers available in ${forestWallpapers}" >&2
      exit 1
    fi

    selection="$(printf '%s\n' "''${wallpapers[@]##*/}" | ${lib.getExe pkgs.rofi} -dmenu -i -p "Forest wallpaper")"
    if [ -z "$selection" ]; then
      exit 0
    fi

    selected_path=""
    for wallpaper in "''${wallpapers[@]}"; do
      if [ "''${wallpaper##*/}" = "$selection" ]; then
        selected_path="$wallpaper"
        break
      fi
    done

    if [ -z "$selected_path" ]; then
      echo "Selected wallpaper not found: $selection" >&2
      exit 1
    fi

    ${lib.getExe' pkgs.coreutils "ln"} -sfn "$selected_path" "$current_path"
    exec ${lib.getExe pkgs.feh} --bg-fill "$selected_path"
  '';

  cpuTemperatureScript = pkgs.writeShellScriptBin "polybar-cpu-temperature" ''
    set -eu

    best_millic=0

    for hwmon in /sys/class/hwmon/hwmon*; do
      [ -d "$hwmon" ] || continue

      sensor_name=""
      if [ -r "$hwmon/name" ]; then
        sensor_name="$(${lib.getExe' pkgs.coreutils "cat"} "$hwmon/name" 2>/dev/null || true)"
      fi

      sensor_match=0
      case "$sensor_name" in
        coretemp|k10temp|zenpower|cpu_thermal|x86_pkg_temp)
          sensor_match=1
          ;;
      esac

      for input in "$hwmon"/temp*_input; do
        [ -r "$input" ] || continue

        base="''${input%_input}"
        label=""
        if [ -r "$base"_label ]; then
          label="$(${lib.getExe' pkgs.coreutils "cat"} "$base"_label 2>/dev/null || true)"
        fi

        include=0
        if [ "$sensor_match" -eq 1 ]; then
          include=1
        else
          case "$label" in
            Package*|Tctl|Tdie|Core*|CPU*)
              include=1
              ;;
          esac
        fi

        [ "$include" -eq 1 ] || continue

        value="$(${lib.getExe' pkgs.coreutils "cat"} "$input" 2>/dev/null || true)"
        if [ -z "$value" ]; then
          continue
        fi
        case "$value" in
          *[!0-9]*)
            continue
            ;;
        esac

        if [ "$value" -gt "$best_millic" ]; then
          best_millic="$value"
        fi
      done
    done

    if [ "$best_millic" -eq 0 ]; then
      for zone in /sys/class/thermal/thermal_zone*; do
        [ -d "$zone" ] || continue
        [ -r "$zone/temp" ] || continue

        zone_type=""
        if [ -r "$zone/type" ]; then
          zone_type="$(${lib.getExe' pkgs.coreutils "cat"} "$zone/type" 2>/dev/null || true)"
        fi

        include=0
        case "$zone_type" in
          x86_pkg_temp|cpu-thermal|cpu_thermal|k10temp|coretemp|soc_thermal)
            include=1
            ;;
        esac
        [ "$include" -eq 1 ] || continue

        value="$(${lib.getExe' pkgs.coreutils "cat"} "$zone/temp" 2>/dev/null || true)"
        if [ -z "$value" ]; then
          continue
        fi
        case "$value" in
          *[!0-9]*)
            continue
            ;;
        esac

        if [ "$value" -gt "$best_millic" ]; then
          best_millic="$value"
        fi
      done
    fi

    if [ "$best_millic" -eq 0 ]; then
      echo " N/A"
      exit 0
    fi

    celsius=$((best_millic / 1000))
    if [ "$celsius" -ge ${toString cfg.temperatureWarn} ]; then
      echo " ''${celsius}°C"
    else
      echo " ''${celsius}°C"
    fi
  '';

  defaultConfig = ''
    [colors]
    background = #1e1e1e
    foreground = #ffffff
    primary = #7aa2f7
    alert = #ff6b6b
    disabled = #666666

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
    font-0 = "JetBrainsMono Nerd Font:style=Regular:size=11;3"
    modules-left = i3 xwindow
    modules-center = clock
    modules-right = layout network disk-io disk-space volume battery cpu memory tray
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
    label =  %date% %time%
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
    format-muted =  <label-muted>
    label-volume = %percentage%%
    label-muted = muted
    label-muted-foreground = ''${colors.disabled}
    ramp-volume-0 = 
    ramp-volume-1 = 
    ramp-volume-2 = 

    [module/battery]
    type = internal/battery
    battery = ${cfg.battery}
    adapter = ${cfg.adapter}
    poll-interval = 5
    time-format = %H:%M
    format-charging = <animation-charging> <label-charging>
    format-discharging = <ramp-capacity> <label-discharging>
    format-full = <ramp-capacity> <label-full>
    label-charging = %percentage%%
    label-discharging = %percentage%%
    label-full = %percentage%%
    ramp-capacity-0 = 
    ramp-capacity-1 = 
    ramp-capacity-2 = 
    ramp-capacity-3 = 
    ramp-capacity-4 = 
    animation-charging-0 = 
    animation-charging-1 = 
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
    ${networkInterfaceConfig}
    interval = 1.0
    ping-interval = 10
    format-connected = <label-connected>
    format-disconnected = <label-disconnected>
    label-connected =  %downspeed%
    label-disconnected = WiFi down
    label-disconnected-foreground = ''${colors.disabled}

    [module/disk-io]
    type = custom/script
    exec = ${diskIoScript}/bin/polybar-disk-io
    interval = 2
    format = <label>
    label = %output%
    label-foreground = ''${colors.primary}

    [module/disk-space]
    type = custom/script
    exec = ${diskCapacityScript}/bin/polybar-disk-capacity
    interval = 30
    format = <label>
    label = %output%
    label-foreground = ''${colors.primary}

    [module/tray]
    type = internal/tray
    tray-position = right
    tray-padding = 2
    tray-background = ''${colors.background}
  '';

  forestConfig = ''
    [color]
    background = #212B30
    foreground = #C4C7C5
    sep = #3F5360
    yellow = #FDD835
    cyan = #4DD0E1
    teal = #00B19F
    indigo = #6C77BB
    red = #EC7875
    pink = #EC407A
    green = #61C766
    blue = #42A5F5
    blue-gray = #6D8895
    orange = #E57C46

    [bar/main]
    monitor = ''${env:MONITOR:}
    width = 100%
    height = ${toString cfg.height}
    offset-x = 0
    offset-y = 0
    position = ${cfg.position}
    fixed-center = true
    background = ''${color.background}
    foreground = ''${color.foreground}
    line-size = 0
    border-size = 0
    padding-left = 2
    padding-right = 2
    module-margin-left = 1
    module-margin-right = 1
    font-0 = "JetBrainsMono Nerd Font:size=10;3"
    font-1 = "JetBrainsMono Nerd Font:size=10;2"
    separator =
    modules-left = i3 xwindow
    modules-center = clock
    modules-right = layout network disk-io disk-space temperature volume battery cpu memory tray
    tray-position = right
    tray-padding = 2
    tray-background = ''${color.background}
    cursor-click = pointer
    enable-ipc = true

    [module/i3]
    type = internal/i3
    format = <label-state> <label-mode>
    index-sort = true
    wrapping-scroll = false
    label-mode = %mode%
    label-mode-padding = 1
    label-mode-foreground = ''${color.background}
    label-mode-background = ''${color.yellow}
    label-focused = %index%
    label-focused-padding = 2
    label-focused-foreground = ''${color.background}
    label-focused-background = ''${color.cyan}
    label-unfocused = %index%
    label-unfocused-padding = 2
    label-visible = %index%
    label-visible-padding = 2
    label-visible-foreground = ''${color.foreground}
    label-visible-background = ''${color.sep}
    label-urgent = %index%
    label-urgent-padding = 2
    label-urgent-foreground = ''${color.background}
    label-urgent-background = ''${color.red}

    [module/xwindow]
    type = internal/xwindow
    label = %title:0:50:%

    [module/clock]
    type = internal/date
    interval = 1
    date = %a, %d %b. %y
    time = %H:%M:%S
    format = <label>
    label =  %date% %time%
    label-foreground = ''${color.yellow}

    [module/layout]
    type = custom/script
    exec = ${layoutIndicatorScript}/bin/layout-indicator
    interval = 1
    click-left = ${layoutToggleScript}/bin/toggle-layout
    format = <label>
    label =  %output%
    label-foreground = ''${color.blue}

    [module/network]
    type = internal/network
    ${networkInterfaceConfig}
    interval = 2
    format-connected = <label-connected>
    format-disconnected = <label-disconnected>
    label-connected =  %downspeed%
    label-connected-foreground = ''${color.cyan}
    label-disconnected =  down
    label-disconnected-foreground = ''${color.sep}

    [module/disk-io]
    type = custom/script
    exec = ${diskIoScript}/bin/polybar-disk-io
    interval = 2
    format = <label>
    label = %output%
    label-foreground = ''${color.blue}

    [module/disk-space]
    type = custom/script
    exec = ${diskCapacityScript}/bin/polybar-disk-capacity
    interval = 30
    format = <label>
    label = %output%
    label-foreground = ''${color.teal}

    [module/temperature]
    type = custom/script
    exec = ${cpuTemperatureScript}/bin/polybar-cpu-temperature
    interval = 1
    format = <label>
    label = %output%
    label-foreground = ''${color.orange}

    [module/volume]
    type = internal/alsa
    master-soundcard = default
    speaker-soundcard = default
    headphone-soundcard = default
    master-mixer = Master
    interval = 5
    format-volume = <ramp-volume> <label-volume>
    format-muted = <label-muted>
    label-volume = %percentage%%
    label-muted =  Muted
    label-muted-foreground = ''${color.sep}
    ramp-volume-0 = 
    ramp-volume-1 = 
    ramp-volume-2 = 
    ramp-volume-foreground = ''${color.blue}

    [module/battery]
    type = internal/battery
    full-at = 99
    battery = ${cfg.battery}
    adapter = ${cfg.adapter}
    poll-interval = 2
    time-format = %H:%M
    format-charging = <label-charging>
    format-charging-prefix = ""
    format-charging-prefix-foreground = ''${color.green}
    format-discharging = <label-discharging>
    format-discharging-prefix = ""
    format-discharging-prefix-foreground = ''${color.pink}
    format-full = <label-full>
    format-full-prefix = ""
    format-full-prefix-foreground = ''${color.green}
    label-charging = " %percentage%%"
    label-discharging = " %percentage%%"
    label-full = " %percentage%%"

    [module/cpu]
    type = internal/cpu
    interval = 1
    format = <label>
    format-prefix = 
    format-prefix-foreground = ''${color.teal}
    label = " %percentage%%"
    label-foreground = ''${color.foreground}

    [module/memory]
    type = internal/memory
    interval = 2
    format = <label>
    format-prefix = 
    format-prefix-foreground = ''${color.indigo}
    label = " %percentage_used%%"
    label-foreground = ''${color.foreground}

    [module/tray]
    type = internal/tray
    tray-position = right
    tray-padding = 2
    tray-background = ''${color.background}
  '';

  polybarConfig = if cfg.theme == "forest" then forestConfig else defaultConfig;
in
{
  options.profiles.desktop.polybar = {
    enable = lib.mkEnableOption "Polybar status bar";

    theme = lib.mkOption {
      type = lib.types.enum [
        "default"
        "forest"
      ];
      default = "default";
      description = "Polybar theme variant.";
    };

    position = lib.mkOption {
      type = lib.types.enum [
        "top"
        "bottom"
      ];
      default = "top";
      description = "Position of the polybar.";
    };

    height = lib.mkOption {
      type = lib.types.int;
      default = 28;
      description = "Height of the polybar in pixels.";
    };

    networkInterface = lib.mkOption {
      type = lib.types.str;
      default = "wlan0";
      description = "Network interface used by the network module, or 'auto' for wireless auto-detection.";
    };

    battery = lib.mkOption {
      type = lib.types.str;
      default = "BAT0";
      description = "Battery name used by the battery module.";
    };

    adapter = lib.mkOption {
      type = lib.types.str;
      default = "AC0";
      description = "Power adapter name used by the battery module.";
    };

    temperatureZone = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = "Thermal zone index used by the temperature module.";
    };

    temperatureBase = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = "Base temperature for Polybar temperature calculations.";
    };

    temperatureWarn = lib.mkOption {
      type = lib.types.int;
      default = 75;
      description = "Warning temperature threshold in Celsius.";
    };

    wallpaper = {
      enable = lib.mkEnableOption "Forest wallpaper picker and apply scripts";

      currentPath = lib.mkOption {
        type = lib.types.str;
        default = "/tmp/polybar-current-wallpaper";
        description = "Stable path for the currently selected wallpaper.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        polybar
        xkb-switch
      ]
      ++ lib.optionals (cfg.theme == "forest" && cfg.wallpaper.enable) [
        feh
        fd
        rofi
        wallpaperApplyScript
        wallpaperPickerScript
      ];

    home.file.".config/polybar/config.ini".text = polybarConfig;

    systemd.user.services = {
      polybar = {
        Unit = {
          Description = "Polybar status bar";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          Type = "simple";
          ExecStart = "${lib.getExe pkgs.polybar} main";
          Restart = "on-failure";
          RestartSec = 3;
        };

        Install.WantedBy = [ "graphical-session.target" ];
      };
    } // lib.optionalAttrs (cfg.theme == "forest" && cfg.wallpaper.enable) {
      forest-wallpaper = {
        Unit = {
          Description = "Apply selected Forest wallpaper";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${lib.getExe wallpaperApplyScript}";
          RemainAfterExit = true;
        };

        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
