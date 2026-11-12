{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.nvix;
  options = builtins.toJSON {
    profile = cfg.package;
    servers = cfg.servers;
  };
in
{
  config = lib.mkIf (cfg.enable && cfg.backend == "native") {
    assertions = [
      {
        assertion = cfg.package == "core";
        message = "The experimental native nvix backend only supports the core profile.";
      }
      {
        assertion = cfg.settings == { } && cfg.extraModules == [ ];
        message = "programs.nvix.settings and extraModules are Nixvim-specific and cannot be used with the native backend.";
      }
      {
        assertion = lib.all (name: builtins.match "[A-Za-z0-9_]+" name != null) (
          builtins.attrNames cfg.servers
        );
        message = "Native nvix server override names may contain only letters, digits and underscores.";
      }
    ];

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withPython3 = true;
      withRuby = true;
      initLua = ''
        vim.g.nvix = vim.json.decode([====[${options}]====])
        require("nvix.startup")
      '';
      extraPackages = with pkgs; [
        coreutils
        curl
        direnv
        dwt1-shell-color-scripts
        fixjson
        ghostscript_headless
        git
        glow
        gnutar
        go
        gotools
        gzip
        imagemagick
        libxml2
        mermaid-cli
        nixfmt
        nodejs
        opentofu
        ripgrep
        shellcheck
        shellharden
        shfmt
        stdenv.cc
        stylua
        taplo
        tectonic
        typstyle
        unzip
        websocat
        yamlfix
      ];
    };

    xdg.configFile."nvim/lua/nvix".source = ./lua/nvix;
  };
}
