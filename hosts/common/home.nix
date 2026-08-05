{
  config,
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
  home.file = {
    "${config.xdg.configHome}/git/git-commit-template.commit".source =
      ./dotfiles/git-commit-template.commit;
  };
  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = "${config.xdg.configHome}/sops/age/keys.txt";
  };
  home.sessionPath = [
    "$GOPATH/bin"
  ];
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    fileWidgetCommand = "fd --type file --follow --hidden --exclude .git";
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.go = {
    enable = true;
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
  programs.eza = {
    enable = true;
    git = true;
    icons = "auto";
    enableZshIntegration = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };
  programs.fd = {
    enable = true;
    extraOptions = [
      "--no-ignore"
      "--absolute-path"
    ];
    ignores = [
      ".git"
      ".hg"
    ];
  };
  programs.ripgrep = {
    enable = true;
    arguments = [
      "--max-columns=150"
      "--max-columns-preview"
      "--hidden"
      "--glob=!.git/*"
      "--colors=line:none"
      "--colors=line:style:bold"
      "--smart-case"
    ];
  };
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
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [
      "--disable-up-arrow"
    ];
  };
  programs.bat = {
    enable = true;
    config = {
      theme = "CatppuccinMocha";
    };
    themes = {
      CatppuccinMocha = {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat";
          rev = "d714cc1d358ea51bfc02550dabab693f70cccea0";
          sha256 = "sha256-Q5B4NDrfCIK3UAMs94vdXnR42k4AXCqZz6sRn8bzmf4=";
        };
        file = "themes/Catppuccin\ Mocha.tmTheme";
      };
    };
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
  programs.lazygit = {
    enable = true;
    settings = {
      gui.theme = {
        lightTheme = true;
        activeBorderColor = [
          "blue"
          "bold"
        ];
        inactiveBorderColor = [ "black" ];
        selectedLineBgColor = [ "default" ];
      };
      git.pagers = [
        {
          pager = "delta --dark --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format=\"lazygit-edit://{path}:{line}\"";
        }
      ];
    };
  };
}
