{ pkgs, lib, ... }:
{
  # https://nixos.wiki/wiki/Neovim
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
    vimdiffAlias = true;
    extraConfig = lib.fileContents ./dotfiles/init.vim;
    coc = {
      enable = true;
      settings = {
        languageserver = {
          bash = {
            command = "bash-language-server";
            args = ["start"];
            filetypes = ["sh"];
            ignoredRootPaths = ["~"];
          };
          golang = {
            command = "gopls";
            rootPatterns = ["go.mod" ".vim/" ".git/" ".hg/"];
            filetypes = ["go"];
            initializationOptions = {};
          };
          nix = {
            command = "nil";
            filetypes = ["nix"];
            rootPatterns = ["flake.nix"];
            settings.nil.formatting = {
              command = [
                (lib.getExe pkgs.nixfmt)
              ];
            };
          };
        };
        "codeLens.enable" = true;
        "coc.preferences.currentFunctionSymbolAutoUpdate" = true;
        "suggest.noselect" = true;
      };
    };
    plugins = with pkgs.vimPlugins; [
      vim-nix
      vim-gitgutter
      nnn-vim
      nvim-treesitter.withAllGrammars
      coc-json
      coc-explorer
    ];
    extraLuaConfig = ''
      require'nvim-treesitter.configs'.setup {
        highlight = {
          enable = true,
        },
      }
    '';
  };
}
