{ config, pkgs, lib, ... }:
let
  terminalCommand = "${lib.getExe pkgs.wezterm}";
  launcherCommand = "${lib.getExe pkgs.rofi} -show drun";
  clipboardCommand = "${lib.getExe pkgs.copyq} toggle";
  emojiCommand = "${lib.getExe pkgs.rofimoji} --selector rofi";
  lockCommand = "${lib.getExe pkgs.i3lock} -c 000000";
  screenshotCopyCommand = "${lib.getExe pkgs.flameshot} gui --raw | ${lib.getExe pkgs.xclip} -selection clipboard -t image/png -i";
in
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

  sops.secrets.halloy = {
    sopsFile = ./secrets/hloy.yaml;
    key = "pwd";
  };

  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true;

  home.sessionVariables = {
    TERMINAL = "wezterm";
    XDG_SESSION_TYPE = "x11";
    XDG_CURRENT_DESKTOP = "i3";
    XDG_SESSION_DESKTOP = "i3";
  };

  home.file.".i3/config".text = ''
    set $mod Mod4

    font pango:JetBrains Mono 10
    floating_modifier $mod

    exec --no-startup-id copyq

    bindsym XF86AudioMute exec amixer -q set Master toggle
    bindsym XF86AudioLowerVolume exec amixer -q set Master 5%-
    bindsym XF86AudioRaiseVolume exec amixer -q set Master 5%+
    bindsym XF86AudioMicMute exec amixer -q set Capture toggle
    bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
    bindsym XF86MonBrightnessUp exec brightnessctl set +5%

    bindsym $mod+Return exec ${terminalCommand}
    bindsym $mod+d exec ${launcherCommand}
    bindsym $mod+v exec vivaldi
    bindsym $mod+g exec kdeconnect-app
    bindsym Print exec flameshot gui
    bindsym $mod+Shift+p exec ${screenshotCopyCommand}
    bindsym $mod+Ctrl+v exec ${clipboardCommand}
    bindsym $mod+Ctrl+space exec ${emojiCommand}
    bindsym $mod+space floating toggle
    bindsym $mod+q kill
    bindsym $mod+f fullscreen toggle
    bindsym $mod+BackSpace exec ${lockCommand}
    bindsym $mod+Shift+e exec i3-msg exit

    bindsym $mod+h focus left
    bindsym $mod+j focus down
    bindsym $mod+k focus up
    bindsym $mod+l focus right
    bindsym $mod+Left focus left
    bindsym $mod+Down focus down
    bindsym $mod+Up focus up
    bindsym $mod+Right focus right

    bindsym $mod+Shift+h move left
    bindsym $mod+Shift+j move down
    bindsym $mod+Shift+k move up
    bindsym $mod+Shift+l move right
    bindsym $mod+Shift+Left move left
    bindsym $mod+Shift+Down move down
    bindsym $mod+Shift+Up move up
    bindsym $mod+Shift+Right move right

    bindsym $mod+Ctrl+h resize shrink width 40 px or 40 ppt
    bindsym $mod+Ctrl+j resize grow height 40 px or 40 ppt
    bindsym $mod+Ctrl+k resize shrink height 40 px or 40 ppt
    bindsym $mod+Ctrl+l resize grow width 40 px or 40 ppt
    bindsym $mod+Ctrl+Left resize shrink width 40 px or 40 ppt
    bindsym $mod+Ctrl+Down resize grow height 40 px or 40 ppt
    bindsym $mod+Ctrl+Up resize shrink height 40 px or 40 ppt
    bindsym $mod+Ctrl+Right resize grow width 40 px or 40 ppt

    bindsym $mod+1 workspace number 1
    bindsym $mod+2 workspace number 2
    bindsym $mod+3 workspace number 3
    bindsym $mod+4 workspace number 4
    bindsym $mod+5 workspace number 5
    bindsym $mod+6 workspace number 6
    bindsym $mod+7 workspace number 7
    bindsym $mod+8 workspace number 8
    bindsym $mod+9 workspace number 9

    bindsym $mod+Shift+1 move container to workspace number 1
    bindsym $mod+Shift+2 move container to workspace number 2
    bindsym $mod+Shift+3 move container to workspace number 3
    bindsym $mod+Shift+4 move container to workspace number 4
    bindsym $mod+Shift+5 move container to workspace number 5
    bindsym $mod+Shift+6 move container to workspace number 6
    bindsym $mod+Shift+7 move container to workspace number 7
    bindsym $mod+Shift+8 move container to workspace number 8
    bindsym $mod+Shift+9 move container to workspace number 9

    bar {
      status_command i3status
    }
  '';

  home.file.".inputrc".text = ''
    "\e[1;5C": forward-word
    "\e[1;5D": backward-word
  '';

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
    flameshot
    bramble
    vivaldi
    wezterm
    st
    dunst
    rofi
    copyq
    rofimoji
    xclip
    networkmanagerapplet
    lxqt.lxqt-policykit
    libreoffice
    signal-desktop
    telegram-desktop
    element-desktop
    discord
    nextcloud-client
    gnucash
  ];

  programs = {
    btop.enable = true;
    halloy = {
      enable = true;
      settings = {
        buffer.channel.topic.enabled = true;
        servers.liberachat = {
          server = "irc.libera.chat";
          use_tls = true;
          nickname = "dminca2";
          nick_password_file = config.sops.secrets.halloy.path;
          channels = [
            "#nixos"
            "#gentoo"
            "#nix-darwin"
            "#nixos-chat"
            "#nixos-de"
            "#yggdrasil"
            "#halloy"
          ];
        };
      };
    };
  };
}
