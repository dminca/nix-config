{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./git.nix
  ];

  profiles.shell.zsh.enable = true;
  profiles.common.shell.enable = true;
  profiles.common.git.enable = true;
  profiles.common.wezterm = {
    enable = true;
    style = "word-jump-only";
    wordJumpMods = "CTRL";
  };
  programs.nvix.enable = true;

  home.username = "dminca";
  home.homeDirectory = "/home/dminca";
  home.stateVersion = "26.05";

  sops = {
    defaultSopsFile = ./secrets/example.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true;

  home.sessionVariables = {
    TERMINAL = "wezterm";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    NIXOS_OZONE_WL = "1";
  };

  # Keep HM session variables visible to user systemd services when launched via UWSM.
  xdg.configFile."uwsm/env".source =
    "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;
    extraConfig = ''
      hl.monitor({
        output = "eDP-1",
        mode = "preferred",
        position = "0x0",
        scale = "1.25",
      })

      hl.config({
        input = {
          kb_layout = "us",
          kb_options = "caps:swapescape",
          repeat_delay = 150,
          repeat_rate = 50,
          natural_scroll = true,
          touchpad = {
            natural_scroll = true,
          },
        }
      })

      hl.config({
        gestures = {
          workspace_swipe_invert = false,
        }
      })

      hl.gesture({
        fingers = 3,
        direction = "horizontal",
        action = "workspace",
      })

      hl.bind("XF86AudioMute", hl.dsp.exec_cmd("amixer -q set Master toggle"))
      hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("amixer -q set Master 5%-"))
      hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("amixer -q set Master 5%+"))
      hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("amixer -q set Capture toggle"))
      hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))
      hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"))

      hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("wezterm"))
      hl.bind("SUPER + D", hl.dsp.exec_cmd("wofi --show drun"))
      hl.bind("SUPER + V", hl.dsp.exec_cmd("vivaldi"))
      hl.bind("SUPER + G", hl.dsp.exec_cmd("kdeconnect-app"))
      hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("flameshot gui"))
      hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("sh -c 'flameshot gui --raw | wl-copy --type image/png'"))
      hl.bind("SUPER + CTRL + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))
      hl.bind("ALT + TAB", hl.dsp.window.cycle_next({ next = true, tiled = true, floating = true }))
      hl.bind("ALT + SHIFT + TAB", hl.dsp.window.cycle_next({ next = false, tiled = true, floating = true }))
      hl.bind("SUPER + SPACE", hl.dsp.window.float({ action = "toggle" }))
      hl.bind("SUPER + Q", hl.dsp.window.close())
      hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
      hl.bind("SUPER + BACKSPACE", hl.dsp.exec_cmd("wlogout"))
      hl.bind("SUPER + SHIFT + E", hl.dsp.exit())

      hl.bind("SUPER + H", hl.dsp.focus({ direction = "left" }))
      hl.bind("SUPER + J", hl.dsp.focus({ direction = "down" }))
      hl.bind("SUPER + K", hl.dsp.focus({ direction = "up" }))
      hl.bind("SUPER + L", hl.dsp.focus({ direction = "right" }))
      hl.bind("SUPER + LEFT", hl.dsp.focus({ direction = "left" }))
      hl.bind("SUPER + DOWN", hl.dsp.focus({ direction = "down" }))
      hl.bind("SUPER + UP", hl.dsp.focus({ direction = "up" }))
      hl.bind("SUPER + RIGHT", hl.dsp.focus({ direction = "right" }))

      hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
      hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
      hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
      hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
      hl.bind("SUPER + SHIFT + LEFT", hl.dsp.window.move({ direction = "left" }))
      hl.bind("SUPER + SHIFT + DOWN", hl.dsp.window.move({ direction = "down" }))
      hl.bind("SUPER + SHIFT + UP", hl.dsp.window.move({ direction = "up" }))
      hl.bind("SUPER + SHIFT + RIGHT", hl.dsp.window.move({ direction = "right" }))

      hl.bind("SUPER + CTRL + H", hl.dsp.window.resize({ x = -40, y = 0, relative = true }))
      hl.bind("SUPER + CTRL + J", hl.dsp.window.resize({ x = 0, y = 40, relative = true }))
      hl.bind("SUPER + CTRL + K", hl.dsp.window.resize({ x = 0, y = -40, relative = true }))
      hl.bind("SUPER + CTRL + L", hl.dsp.window.resize({ x = 40, y = 0, relative = true }))
      hl.bind("SUPER + CTRL + LEFT", hl.dsp.window.resize({ x = -40, y = 0, relative = true }))
      hl.bind("SUPER + CTRL + DOWN", hl.dsp.window.resize({ x = 0, y = 40, relative = true }))
      hl.bind("SUPER + CTRL + UP", hl.dsp.window.resize({ x = 0, y = -40, relative = true }))
      hl.bind("SUPER + CTRL + RIGHT", hl.dsp.window.resize({ x = 40, y = 0, relative = true }))

      hl.bind("SUPER + 1", hl.dsp.focus({ workspace = "1" }))
      hl.bind("SUPER + 2", hl.dsp.focus({ workspace = "2" }))
      hl.bind("SUPER + 3", hl.dsp.focus({ workspace = "3" }))
      hl.bind("SUPER + 4", hl.dsp.focus({ workspace = "4" }))
      hl.bind("SUPER + 5", hl.dsp.focus({ workspace = "5" }))
      hl.bind("SUPER + 6", hl.dsp.focus({ workspace = "6" }))
      hl.bind("SUPER + 7", hl.dsp.focus({ workspace = "7" }))
      hl.bind("SUPER + 8", hl.dsp.focus({ workspace = "8" }))
      hl.bind("SUPER + 9", hl.dsp.focus({ workspace = "9" }))

      hl.bind("SUPER + SHIFT + 1", hl.dsp.window.move({ workspace = "1" }))
      hl.bind("SUPER + SHIFT + 2", hl.dsp.window.move({ workspace = "2" }))
      hl.bind("SUPER + SHIFT + 3", hl.dsp.window.move({ workspace = "3" }))
      hl.bind("SUPER + SHIFT + 4", hl.dsp.window.move({ workspace = "4" }))
      hl.bind("SUPER + SHIFT + 5", hl.dsp.window.move({ workspace = "5" }))
      hl.bind("SUPER + SHIFT + 6", hl.dsp.window.move({ workspace = "6" }))
      hl.bind("SUPER + SHIFT + 7", hl.dsp.window.move({ workspace = "7" }))
      hl.bind("SUPER + SHIFT + 8", hl.dsp.window.move({ workspace = "8" }))
      hl.bind("SUPER + SHIFT + 9", hl.dsp.window.move({ workspace = "9" }))
    '';
  };

  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.waybar}/bin/waybar";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.dunst = {
    Unit = {
      Description = "Dunst notification daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.dunst}/bin/dunst";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.cliphist = {
    Unit = {
      Description = "Clipboard history daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.polkit-agent = {
    Unit = {
      Description = "LXQt policykit agent";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    alsa-utils
    brightnessctl
    cliphist
    flameshot
    vivaldi
    wezterm
    waybar
    dunst
    wofi
    wlogout
    wl-clipboard
    grim
    slurp
    hyprlock
    hypridle
    xdg-desktop-portal-hyprland
    networkmanagerapplet
    lxqt.lxqt-policykit
  ];

  xdg.configFile."wlogout/layout".text = ''
    {
      "label" : "shutdown",
      "action" : "systemctl poweroff",
      "text" : "Shutdown",
      "keybind" : "s"
    }
    {
      "label" : "reboot",
      "action" : "systemctl reboot",
      "text" : "Reboot",
      "keybind" : "r"
    }
    {
      "label" : "logout",
      "action" : "hyprctl dispatch exit",
      "text" : "Exit",
      "keybind" : "e"
    }
    {
      "label" : "suspend",
      "action" : "systemctl suspend",
      "text" : "Suspend",
      "keybind" : "u"
    }
    {
      "label" : "lock",
      "action" : "hyprlock",
      "text" : "Lock",
      "keybind" : "l"
    }
    {
      "label" : "hibernate",
      "action" : "systemctl hibernate",
      "text" : "Hibernate",
      "keybind" : "h"
    }
  '';

  xdg.configFile."wlogout/style.css".text = ''
    * {
      font-family: "JetBrains Mono Nerd Font";
      background-image: none;
      transition: 20ms;
    }

    window {
      background-color: rgba(12, 12, 12, 0.1);
    }

    button {
      color: #e0def4;
      font-size: 20px;
      background-repeat: no-repeat;
      background-position: center;
      background-size: 25%;
      border-style: solid;
      background-color: rgba(12, 12, 12, 0.3);
      border: 3px solid #e0def4;
      box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
    }

    button:focus,
    button:active,
    button:hover {
      color: #c4a7e7;
      background-color: rgba(12, 12, 12, 0.5);
      border: 3px solid #c4a7e7;
    }

    #logout, #suspend, #shutdown, #reboot, #lock, #hibernate {
      margin: 10px;
      border-radius: 20px;
    }
  '';

  xdg.configFile."waybar/config".text = builtins.toJSON {
    layer = "top";
    position = "top";
    height = 34;
    spacing = 4;
    modules-left = [ "hyprland/workspaces" ];
    modules-center = [ "clock" ];
    modules-right = [
      "cpu"
      "memory"
      "temperature"
      "battery"
      "backlight"
      "tray"
      "network"
      "pulseaudio"
      "custom/power"
    ];
    cpu = {
      format = " {usage}%";
      tooltip = true;
    };
    memory = {
      format = "󰍛 {percentage}%";
      tooltip = true;
    };
    temperature = {
      format = " {temperatureC}°C";
      tooltip = true;
    };
    battery = {
      format = "󰁹 {capacity}%";
      states = {
        warning = 30;
        critical = 15;
      };
      tooltip = true;
    };
    backlight = {
      format = "󰃠 {percent}%";
      tooltip = true;
    };
    network = {
      format-wifi = "󰖩 {essid} {bandwidthDownBits}";
      format-ethernet = "󰈀 {ipaddr}";
      format-disconnected = "󰖪";
      tooltip = true;
    };
    pulseaudio = {
      format = " {volume}%";
      format-muted = "󰖁 muted";
      tooltip = true;
    };
    "custom/power" = {
      format = "⏻";
      tooltip = false;
      on-click = "${pkgs.wlogout}/bin/wlogout";
    };
  };

  xdg.configFile."waybar/style.css".text = ''
    * {
      border: none;
      border-radius: 0px;
      font-family: "JetBrains Mono Nerd Font";
      font-weight: bold;
      font-size: 15px;
      min-height: 13px;
    }

    window#waybar {
      background-color: rgba(0, 0, 0, 0);
    }

    #clock,
    #tray,
    #network,
    #pulseaudio,
    #cpu,
    #memory,
    #temperature,
    #battery,
    #backlight,
    #custom-power,
    #workspaces {
      color: #e0def4;
      background: #232136;
      margin: 4px 0px 4px 0px;
      opacity: 1;
      border: 0px solid #181825;
      padding-left: 10px;
      padding-right: 10px;
    }

    #custom-power {
      margin-right: 9px;
      padding-left: 12px;
      padding-right: 12px;
      border-radius: 0px 22px 22px 0px;
    }

    #workspaces {
      padding-left: 5px;
      padding-right: 5px;
      border-radius: 22px 0px 0px 22px;
      margin-left: 9px;
    }
  '';
}
