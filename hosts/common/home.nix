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
    (nerdfonts.override { fonts = [ "Hack" ]; })
    #################
    # shell tooling #
    #################
    go
    bat
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
  programs.nnn.enable = true;
  programs.eza = {
    enable = true;
    git = true;
    icons = true;
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
  programs.alacritty = {
    enable = true;
    settings = {
      live_config_reload = true;
      colors.draw_bold_text_with_bright_colors = true;
      window = {
        opacity = 1.0;
        dimensions = {
          columns = 0;
          lines = 0;
        };
        padding = {
          x = 2;
          y = 2;
        };
        decorations = "none";
      };
      font = {
        size = 10;
      };
      font.normal = {
        family = "Hack Nerd Font";
      };
      font.bold = {
        family = "Hack Nerd Font";
      };
      env = {
        TERM = "screen-256color";
      };
      font.italic = {
        family = "Hack Nerd Font";
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
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      manager = {
        sort_dir_first = true;
      };
    };
  };
}

