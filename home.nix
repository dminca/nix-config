{ config, pkgs, lib, ... }:

{
  home.username = "dminca";
  home.homeDirectory = "/Users/dminca";
  home.stateVersion = "23.11";
  home.packages = with pkgs; [
    ################
    # core tooling #
    ################
    git
    git-lfs
    nil
    nixpkgs-fmt
    #################
    # shell tooling #
    #################
    fzf
    zoxide
    python3
    go
    gnupg
    bat
    jsonnet
    exercism
    sipcalc
    hugo
    nodejs_21
    openssl
    operator-sdk
    gum
    lsd
    ########
    # Apps #
    ########
    warp-terminal
    vscodium
    element-desktop
  ];

  nixpkgs.config.allowUnfree = true;

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

  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = "${config.xdg.configHome}/sops/age/keys.txt";
  };

  home.sessionPath = [
    "$GOPATH/bin"
  ];

  home.file = {
    "${config.xdg.configHome}/git/git-commit-template.commit".source = ./dotfiles/git-commit-template.commit;
  };

  programs.home-manager.enable = true;

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.go = {
    enable = true;
    goPath = "Projects/misc/gopath";
  };
  programs.tmux = {
    enable = true;
    clock24 = true;
    keyMode = "vi";
    prefix = "C-a";
    historyLimit = 5000;
    terminal = "screen-256color";
    extraConfig = lib.fileContents ./dotfiles/tmux.conf;
  };
  programs.powerline-go = {
    enable = true;
    settings = {
      cwd-max-depth = 2;
    };
    modules = [
      "user"
      "host"
      "ssh"
      "cwd"
      "perms"
      "git"
      "hg"
      "jobs"
      "exit"
      "root"
    ];
  };
  programs.nnn.enable = true;
}
