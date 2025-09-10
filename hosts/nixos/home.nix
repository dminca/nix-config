{
  config,
  pkgs,
  lib,
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
    vivaldi
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
  programs.tmux = {
    enable = true;
    clock24 = true;
    keyMode = "vi";
    prefix = "C-a";
    extraConfig = ''
      # Fix ctrl+left/right keys work right
      set-window-option -g xterm-keys on
      # tmux inception
      bind a send-prefix
      # yazi
      set -g allow-passthrough on
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM
      # Set 'v' for vertical and 'h' for horizontal split
      bind v split-window -h -c '#{pane_current_path}'
      bind b split-window -v -c '#{pane_current_path}'
      # vim-like pane switching
      bind -r k select-pane -U
      bind -r j select-pane -D
      bind -r h select-pane -L
      bind -r l select-pane -R
      # vim-like pane resizing
      bind -r C-k resize-pane -U
      bind -r C-j resize-pane -D
      bind -r C-h resize-pane -L
      bind -r C-l resize-pane -R
      # remove default binding since replacing
      unbind %
      unbind Up
      unbind Down
      unbind Left
      unbind Right
      unbind C-Up
      unbind C-Down
      unbind C-Left
      unbind C-Right
    '';
    terminal = "tmux-256color";
    historyLimit = 5000;
    baseIndex = 1;
    secureSocket = true;
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
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      manager = {
        sort_dir_first = true;
      };
    };
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
        file ="themes/Catppuccin\ Mocha.tmTheme";
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
      terminal.shell.program = lib.getExe pkgs.tmux;
      terminal.shell.args = [
        "new-session"
        "-A"
        "-D"
        "-s"
        "main"
      ];
    };
  };
  programs.lazygit = {
    enable = true;
    settings = {
      gui.theme = {
        lightTheme = true;
        activeBorderColor = [ "blue" "bold" ];
        inactiveBorderColor = [ "black" ];
        selectedLineBgColor = [ "default" ];
      };
    };
  };
}

