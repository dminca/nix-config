{
  pkgs,
  lib,
  ...
}:
{
  # https://nixos.wiki/wiki/Neovim
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
    vimdiffAlias = true;
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
                (lib.getExe pkgs.nixfmt-classic)
              ];
            };
          };
        };
        "codeLens.enable" = true;
        "coc.preferences.currentFunctionSymbolAutoUpdate" = true;
        "suggest.noselect" = true;
        "explorer.icon.enableNerdfont" = true;
      };
    };
    plugins = with pkgs.vimPlugins; [
      vim-nix
      vim-gitgutter
      nnn-vim
      nvim-treesitter.withAllGrammars
      coc-json
      coc-explorer
      lualine-nvim
      telescope-nvim
    ];
    extraLuaConfig = ''
      vim.cmd.colorscheme('zaibatsu')
      vim.o.termguicolors = true
      require'nvim-treesitter.configs'.setup {
        highlight = {
          enable = true,
        },
      }
      require('lualine').setup {
        options = {
          theme  = 'dracula',
        },
        sections = {
          lualine_a = {'mode'},
          lualine_b = {
            'branch',
            'diff',
            {
              'diagnostics',
              sources = { 'nvim_diagnostic', 'coc' },
              sections = { 'error', 'warn', 'info', 'hint' },
              diagnostics_color = {
                error = 'DiagnosticError',
                warn  = 'DiagnosticWarn',
                info  = 'DiagnosticInfo',
                hint  = 'DiagnosticHint',
              },
              symbols = {error = 'E', warn = 'W', info = 'I', hint = 'H'},
              colored = true,
            },
          },
          lualine_c = {
            {
              'filename',
              path = 1,
            },
          },
        },
        inactive_sections = {
          lualine_c = {
            {
              'filename',
              path = 1,
            },
          },
          lualine_x = {'location'},
        },
        tabline = {
          lualine_a = {'tabs'},
        },
      }
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
      vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
      vim.o.grepprg = 'rg --vimgrep'
      vim.o.grepformat = '%f:%l:%c:%m,%f|%l col %c|%m'
    '';
  };
}

