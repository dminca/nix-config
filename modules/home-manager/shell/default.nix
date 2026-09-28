{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.profiles.common.shell;
in
{
  options.profiles.common.shell = {
    enable = lib.mkEnableOption "shared Home Manager shell productivity profile";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      SOPS_AGE_KEY_FILE = "${config.xdg.configHome}/sops/age/keys.txt";
      ZIGGITY_CONFIG = "${config.xdg.configHome}/ziggity/config.ini";
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

    # ziggity replaces lazygit; see modules/nvix/plugins/snacks/ziggity.nix for
    # the Neovim keymap. This global config reuses the running Neovim instance
    # for `e` (the same $NVIM-remote-send trick lazygit used).
    xdg.configFile."ziggity/config.ini".text = ''
      editor_command = [ -z "$NVIM" ] && (nvim -- {{filename}}) || (nvim --server "$NVIM" --remote-send "q" && nvim --server "$NVIM" --remote {{filename}})
    '';
  };
}
