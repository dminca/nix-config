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
    defaultSopsFile = ./secrets/example.yaml;
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

  programs.go = {
    env = {
      GOPATH = "Projects/misc/gopath";
    };
  };
}
