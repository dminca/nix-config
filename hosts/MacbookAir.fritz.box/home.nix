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
    yt-dlp
    mpv-unwrapped
    ########
    # Apps #
    ########
  ];

  sops = {
    defaultSopsFile = ./secrets/example.yaml;
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
  };
  sops.secrets.codeberg = {
    sopsFile = ./secrets/gitconfig_identities.yaml;
    path = "${config.xdg.configHome}/git/codeberg";
  };
  sops.secrets.gitlab = {
    sopsFile = ./secrets/gitconfig_identities.yaml;
    path = "${config.xdg.configHome}/git/gitlab";
  };
  sops.secrets.github = {
    sopsFile = ./secrets/gitconfig_identities.yaml;
    path = "${config.xdg.configHome}/git/github";
  };

  programs.go = {
    goPath = "Projects/misc/gopath";
  };
}
