{
  pkgs,
  ...
}:
{
  home.stateVersion = "23.11";
  home.packages = with pkgs; [
    ################
    # core tooling #
    ################
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
    raycast
    blender
  ];
}


