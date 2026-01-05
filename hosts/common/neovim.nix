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
      nvim-treesitter.withAllGrammars
      coc-json
      coc-explorer
      lualine-nvim
      telescope-nvim
      diffview-nvim
      yazi-nvim
      plenary-nvim
    ];
    extraLuaConfig = ''
      -- Text, tab and indent settings
      vim.opt.expandtab = true
      vim.opt.smarttab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2
      vim.opt.autoindent = true
      vim.opt.smartindent = true
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.shellcmdflag = vim.opt.shellcmdflag + 'i'

      -- Netrw file manager settings
      vim.g.netrw_keepdir = 0
      vim.g.netrw_banner = 0
      vim.g.netrw_liststyle = 3
      vim.g.netrw_browse_split = 4
      vim.g.netrw_winsize = 25

      -- Display settings
      vim.opt.colorcolumn = '79'
      vim.opt.hlsearch = true
      vim.opt.listchars = { tab = '  ', trail = '·', nbsp = '_' }
      vim.opt.list = true
      vim.opt.magic = true
      vim.opt.showmatch = true
      vim.opt.mat = 2
      vim.opt.background = 'dark'

      -- Encoding and file format
      vim.opt.encoding = 'utf8'
      vim.opt.fileformats = { 'unix', 'dos', 'mac' }

      -- Terminal color support
      if vim.env.COLORTERM == 'gnome-terminal' then
        vim.opt.t_Co = 256
      end

      require'nvim-treesitter.config'.setup {
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
      local actions = require("telescope.actions")
      local builtin = require("telescope.builtin")
      require('telescope').setup{
        defaults = {
          mappings = {
            i = {
              ["<leader>fo"] = actions.send_selected_to_qflist + actions.open_qflist,
            },
          },
        },
      }
      vim.o.grepprg = '${lib.getExe pkgs.ripgrep} --vimgrep'
      vim.o.grepformat = '%f:%l:%c:%m,%f|%l col %c|%m'
      require('diffview').setup {
          view = {
              merge_tool = {
                  layout = "diff4_mixed",
                  disable_diagnostics = true,
              },
          },
      }
      -- || Custom keybindings ||
      -- CoC settings
      -- Use tab for trigger completion with characters ahead and navigate
      vim.keymap.set('i', '<TAB>', function()
        if vim.fn['coc#pum#visible']() ~= 0 then
          return vim.fn['coc#pum#next'](1)
        else
          local col = vim.fn.col('.') - 1
          if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
            return '<Tab>'
          else
            return vim.fn['coc#refresh']()
          end
        end
      end, { expr = true, silent = true })
      vim.keymap.set('i', '<S-TAB>', function()
        return vim.fn['coc#pum#visible']() ~= 0 and vim.fn['coc#pum#prev'](1) or '<C-h>'
      end, { expr = true, silent = true })
      -- GoTo code navigation
      vim.keymap.set('n', 'gd', '<Plug>(coc-definition)', { silent = true })
      vim.keymap.set('n', 'gy', '<Plug>(coc-type-definition)', { silent = true })
      vim.keymap.set('n', 'gi', '<Plug>(coc-implementation)', { silent = true })
      vim.keymap.set('n', 'gr', '<Plug>(coc-references)', { silent = true })
      -- Symbol renaming
      vim.keymap.set('n', '<leader>rn', '<Plug>(coc-rename)', { silent = true })
      -- CoC Explorer
      vim.keymap.set('n', '<space>f', ':CocCommand explorer<CR>', { silent = true })
      vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
      vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
      vim.keymap.set('n', '<C-n>', ':cnext<CR>', { silent = true })
      vim.keymap.set('n', '<C-p>', ':cprevious<CR>', { silent = true })
      vim.keymap.set('n', '<leader>-', function()
        require('yazi').yazi()
      end)

      -- Highlight the symbol and its references when holding the cursor
      vim.api.nvim_create_autocmd('CursorHold', {
        pattern = '*',
        callback = function()
          vim.fn.CocActionAsync('highlight')
        end,
      })
    '';
  };
}
