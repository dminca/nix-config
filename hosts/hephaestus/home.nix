{
  config,
  pkgs,
  lib,
  ...
}:
let
  buildFirefoxXpiAddon =
    {
      pname,
      version,
      addonId,
      url,
      sha256,
      meta ? { },
    }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version meta;
      src = pkgs.fetchurl {
        inherit url sha256;
      };
      dontUnpack = true;
      installPhase = ''
        runHook preInstall
        install -Dm644 "$src" "$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${addonId}.xpi"
        runHook postInstall
      '';
    };
in
{
  imports = [
    ./git.nix
  ];

  profiles.shell.zsh.enable = true;
  profiles.common.shell.enable = true;
  profiles.common.git.enable = true;
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
  };

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
    gnucash
    f2
    doggo
    drawio
    witr
    bind
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
    firefox = {
      enable = true;
      profiles.default = {
        isDefault = true;
        settings = {
          "extensions.autoDisableScopes" = 0;
        };
        extensions.packages = [
          (buildFirefoxXpiAddon {
            pname = "hister";
            version = "0.30.0";
            addonId = "{f0bda7ce-0cda-42dc-9ea8-126b20fed280}";
            url = "https://addons.mozilla.org/firefox/downloads/file/4934117/hister-0.30.0.xpi";
            sha256 = "sha256-PIXN+9Mt0AsKWUU6WgFa127UsOonB5y62hrtkuSesOM=";
            meta = {
              description = "Web history on steroids";
              homepage = "https://addons.mozilla.org/en-US/firefox/addon/hister/";
              platforms = lib.platforms.all;
            };
          })
          (buildFirefoxXpiAddon {
            pname = "bramble";
            version = "1.23.0";
            addonId = "firefox@bramble.app";
            url = "https://addons.mozilla.org/firefox/downloads/file/4999297/bramble-1.23.0.xpi";
            sha256 = "sha256-NZbkM4HNtyjjyv+hWAhINa9i3roYO32NE2rUdnbTZEk=";
            meta = {
              description = "Local-first, encrypted password manager";
              homepage = "https://addons.mozilla.org/en-US/firefox/addon/bramble/";
              platforms = lib.platforms.all;
            };
          })
        ];
      };
    };
  };
}
