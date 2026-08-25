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
  programs.alacritty = {
    enable = true;
    settings = {
      general.live_config_reload = true;
      colors.draw_bold_text_with_bright_colors = true;
      window = {
        opacity = 0.8;
        blur = true;
        padding = {
          x = 2;
          y = 2;
        };
        decorations = "buttonless";
        option_as_alt = "both";
      };
      font = {
        size = 12;
      };
      font.normal = {
        family = "JetBrainsMono Nerd Font";
      };
      font.bold = {
        family = "JetBrainsMono Nerd Font";
      };
      font.italic = {
        family = "JetBrainsMono Nerd Font";
      };
      # Word jump with Ctrl-Left/Right
      keyboard.bindings = [
        {
          key = "Right";
          mods = "Control";
          chars = "\\u001BF";
        }
        {
          key = "Left";
          mods = "Control";
          chars = "\\u001BB";
        }
      ];
    };
  };
}
