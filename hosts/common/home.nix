{
  config,
  pkgs,
  lib,
  ...
}:
{
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
    #################
    # shell tooling #
    #################
    go
    sipcalc
    hugo
    openssl
    operator-sdk
    gum
    ########
    # Apps #
    ########
  ];
  nixpkgs.config.allowUnfree = true;
  fonts.fontconfig.enable = true;
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
    extraConfig = lib.fileContents ./dotfiles/tmux.conf;
    terminal = "tmux-256color";
    historyLimit = 5000;
    baseIndex = 1;
    secureSocket = true;
    plugins = with pkgs.tmuxPlugins; [
      nord
    ];
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
    themeFile = "Catppuccin-Mocha";
    extraConfig = ''
      tab_bar_min_tabs            1
      tab_bar_edge                bottom
      tab_bar_style               powerline
      tab_powerline_style         slanted
      tab_title_template          {title}{' :{}:'.format(num_windows) if num_windows > 1 else ''\}
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
      live_config_reload = true;
      colors.draw_bold_text_with_bright_colors = true;
      window = {
        blur = true;
        padding = {
          x = 2;
          y = 2;
        };
        decorations = "transparent";
      };
      font = {
        size = 10;
      };
      font.normal = {
        family = "JetBrainsMono Nerd Font";
      };
      font.bold = {
        family = "JetBrainsMono Nerd Font";
      };
      env = {
        TERM = "screen-256color";
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

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    extensions = with pkgs.vscode-extensions; [
      jnoortheen.nix-ide
      redhat.vscode-yaml
      golang.go
      oderwat.indent-rainbow
    ];
    userSettings = {
      "indentRainbow.colors" = [
        "rgba(255,255,64,0.07)"
        "rgba(127,255,127,0.07)"
        "rgba(255,127,255,0.07)"
        "rgba(79,236,236,0.07)"
      ];
      "workbench.sideBar.location" = "right";
      "editor.renderWhitespace" = "all";
      "editor.rulers" = [ 79 ];
      "redhat.telemetry.enabled" = false;
      "breadcrumbs.enabled" = true;
      "explorer.autoReveal" = false;
      "explorer.compactFolders" = true;
      "go.toolsManagement.autoUpdate" = true;
      "editor.fontFamily" = "JetBrainsMono Nerd Font";
      "editor.fontLigatures" = false;
      "editor.fontSize" = 12;
      "gitlens.launchpad.indicator.enabled" = false;
      "nix.formatterPath" = "${lib.getExe pkgs.nixfmt-classic}";
      "nix.serverPath" = "${lib.getExe pkgs.nil}";
      "nix.enableLanguageServer" = true;
      "window.autoDetectColorScheme" = true;
      "workbench.preferredDarkColorTheme" = "Default Dark Modern";
      "workbench.preferredHighContrastColorTheme" = "Default Light Modern";
      "files.autoSave" = "onFocusChange";
    };
    keybindings = [
      {
        key = "ctrl+shift+q";
        command = "workbench.action.toggleMaximizedPanel";
      }
      {
        key = "ctrl+shift+left";
        command = "workbench.action.splitEditorLeft";
      }
      {
        key = "ctrl+shift+right";
        command = "workbench.action.splitEditorRight";
      }
      {
        key = "ctrl+shift+down";
        command = "workbench.action.splitEditorDown";
      }
      {
        key = "ctrl+shift+up";
        command = "workbench.action.splitEditorUp";
      }
      {
        key = "ctrl+cmd+up";
        command = "workbench.action.moveEditorToAboveGroup";
      }
      {
        key = "ctrl+cmd+down";
        command = "workbench.action.moveEditorToBelowGroup";
      }
      {
        key = "cmd+\\";
        command = "-workbench.action.splitEditor";
      }
    ];
  };
}
