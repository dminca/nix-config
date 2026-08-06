{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.programs.nvix;

  nvixPlugins = {
    common = ./plugins/common;
    buffer = ./plugins/buffer.nix;
    ux = ./plugins/ux.nix;
    snacks = ./plugins/snacks;
    noice = ./plugins/noice.nix;
    git = ./plugins/git.nix;
    lualine = ./plugins/lualine;
    firenvim = ./plugins/firenvim.nix;
    leetcode = ./plugins/leetcode.nix;
    treesitter = ./plugins/treesitter.nix;
    blink-cmp = ./plugins/blink-cmp.nix;
    lang = ./plugins/lang;
    lsp = ./plugins/lsp;
    autosession = ./plugins/autosession.nix;
    ai = ./plugins/ai;
    tex = ./plugins/tex.nix;
  };

  bareModules = [
    nvixPlugins.common
    nvixPlugins.buffer
    nvixPlugins.ux
    nvixPlugins.snacks
  ];

  coreModules = bareModules ++ [
    nvixPlugins.noice
    nvixPlugins.git
    nvixPlugins.lualine
    nvixPlugins.firenvim
    nvixPlugins.leetcode
    nvixPlugins.treesitter
    nvixPlugins.blink-cmp
    nvixPlugins.lang
    nvixPlugins.lsp
    nvixPlugins.autosession
  ];

  packageModules =
    {
      bare = bareModules;
      core = coreModules;
      full = coreModules ++ [ nvixPlugins.tex nvixPlugins.ai ];
    }
    .${cfg.package};

in
{
  imports = [ inputs.nixvim.homeManagerModules.nixvim ];

  options.programs.nvix = {
    enable = lib.mkEnableOption "the vendored nvix Neovim package";

    package = lib.mkOption {
      type = lib.types.enum [
        "bare"
        "core"
        "full"
      ];
      default = "core";
      description = "Which bundled nvix module set to install.";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra nixvim option overrides merged after the bundled nvix modules.";
      example = lib.literalExpression ''
        {
          plugins.codecompanion.enable = false;
          plugins.lsp.servers.cue.enable = true;
        }
      '';
    };

    extraModules = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      default = [ ];
      description = "Additional nixvim modules appended after the bundled nvix modules.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.nixvim = lib.mkMerge [
      {
        enable = true;
        defaultEditor = true;
        vimdiffAlias = true;
        viAlias = lib.mkDefault true;
        vimAlias = lib.mkDefault true;
        imports = packageModules ++ cfg.extraModules;
      }
      cfg.settings
    ];
  };
}
