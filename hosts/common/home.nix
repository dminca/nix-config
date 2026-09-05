{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    ################
    # core tooling #
    ################
    git-lfs
    nil
    nixfmt
    bash-language-server
    nerd-fonts.jetbrains-mono
    xh
    tcptraceroute
    doggo
    nh
    #################
    # shell tooling #
    #################
    go
    gopls
    sipcalc
    hugo
    openssl
    operator-sdk
    gum
    ########
    # Apps #
    ########
    raycast
    wireshark
  ];
  nixpkgs.config.allowUnfree = true;
  fonts.fontconfig.enable = true;
  programs.home-manager.enable = true;
  programs.kitty = {
    enable = true;
    font.name = "JetBrainsMono Nerd Font";
    extraConfig = ''
      tab_bar_min_tabs            1
      tab_bar_edge                bottom
      tab_bar_style               powerline
      tab_powerline_style         slanted
      tab_title_template          {title}{' :{}:'.format(num_windows) if num_windows > 1 else ''\}
      hide_window_decorations     titlebar-only
    '';
  };
}
