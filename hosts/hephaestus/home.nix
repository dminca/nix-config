{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./git.nix
    ../../modules/home-manager/firefox
    ../../modules/home-manager/zed
    ../../modules/home-manager/flow-tube
  ];

  profiles.shell.zsh.enable = true;
  profiles.common.shell.enable = true;
  profiles.common.git.enable = true;
  profiles.common.tmux.enable = true;
  profiles.common.tmux.launchOnTerminalOpen = true;
  profiles.common.st.enable = true;
  profiles.ai.hermes = {
    enable = true;
    openrouter.enable = true;
    scanOnInstall = false;
  };
  profiles.common.wezterm = {
    enable = true;
    style = "word-jump-only";
    enableWordJumpBindings = false;
  };
  profiles.common.hunk.enable = true;
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

  sops.secrets.memos_access_token = {
    sopsFile = ./secrets/memos.yaml;
    key = "MEMOS_ACCESS_TOKEN";
  };

  home.sessionVariables = {
    MEMOS_BASE_URL = "https://notes.mrbl.dedyn.io";
    MEMOS_ACCESS_TOKEN = "$(cat ${config.sops.secrets.memos_access_token.path})";
  };

  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    alsa-utils
    brightnessctl
    vivaldi
    wezterm
    libreoffice
    signal-desktop
    telegram-desktop
    element-desktop
    discord
    nextcloud-client
    f2
    doggo
    drawio
    witr
    bind
    xclip
    copyq
    gnucash
    pkgs.perlPackages.FinanceQuote
    # photography
    krita
    gimp
    inkscape
    blender
    darktable
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
    yazi = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
