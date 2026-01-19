{
  config,
  pkgs,
  ...
}:

{
  home.username = "dminca";
  home.homeDirectory = "/Users/dminca";
  home.stateVersion = "23.11";
  home.packages = with pkgs; [
    #################
    # shell tooling #
    #################
    gnupg
    exercism
    hugo
    operator-sdk
    ffmpeg
    f2
    btop
    ########
    # Apps #
    ########
    discord
    devenv
  ];

  sops = {
    #defaultSopsFile = ./secrets/example.yaml;
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
  };
  sops.secrets.codeberg = {
    sopsFile = ./secrets/gitconfig_identities.yaml;
    key = "codeberg";
  };
  sops.secrets.gitlab = {
    sopsFile = ./secrets/gitconfig_identities.yaml;
    key = "gitlab";
  };
  sops.secrets.github = {
    sopsFile = ./secrets/gitconfig_identities.yaml;
    key = "github";
  };
  sops.secrets.halloy = {
    sopsFile = ./secrets/hloy.txt;
  };

  programs.go = {
    env = {
      GOPATH = "Projects/misc/gopath";
    };
  };
  programs.halloy = {
    enable = true;
    settings = {
      buffer.channel.topic.enabled = true;
      servers.liberachat = {
        server = "irc.libera.chat";
        use_tls = true;
        nickname = "dminca";
        #nick_password_file = config.sops.secrets.halloy.path;
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
}
