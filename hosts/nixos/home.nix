{
  config,
  pkgs,
  ...
}:
{
  home.stateVersion = "23.11";
  home.packages = with pkgs; [
    ################
    # core tooling #
    ################
    git
    git-lfs
    nil
    nixfmt-classic
    nodePackages.bash-language-server
    nerd-fonts.jetbrains-mono
    xh
    tcptraceroute
    doggo
    #################
    # shell tooling #
    #################
    go
    sipcalc
    hugo
    openssl
    operator-sdk
    gum
    yt-dlp
    ########
    # Apps #
    ########
    blender
  ];
  programs.home-manager.enable = true;
  home.file = {
    "${config.xdg.configHome}/git/git-commit-template.commit".source = ./dotfiles/git-commit-template.commit;
    "${config.xdg.configHome}/yazi/theme.toml".source =
      pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "yazi";
        rev = "9bfdccc2b78d7493fa5c5983bc176a0bc5fef164";
        sha256 = "sha256-a2X9WToZmctD1HZVqN9A512iPd+3dtjRloBEifgteF4=";
      } + "/themes/mocha.toml";
  };
  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = "${config.xdg.configHome}/sops/age/keys.txt";
  };
  home.sessionPath = [
    "$GOPATH/bin"
  ];
}

