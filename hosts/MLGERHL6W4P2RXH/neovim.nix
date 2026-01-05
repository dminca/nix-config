{
  lib,
  pkgs,
  ...
}:
{
  programs.neovim = {
    coc = {
      settings = {
        languageserver = {
          helm = {
            command = lib.getExe pkgs.helm-ls;
            args = ["serve"];
            filetypes = ["helm" "helmfile"];
            rootPatterns = ["Chart.yaml"];
          };
          jsonnet = {
            command = lib.getExe pkgs.jsonnet-language-server;
            args = [
              "-t"
              "-J"
              "lib"
            ];
            rootPatterns = [".git/" "jsonnetfile.json"];
            filetypes = ["jsonnet" "libsonnet"];
          };
        };
      };
    };
    extraLuaConfig = ''
      -- Basic settings
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.shellcmdflag = vim.opt.shellcmdflag + 'i'

      -- Netrw file manager settings
      vim.g.netrw_keepdir = 0
      vim.g.netrw_banner = 0
      vim.g.netrw_liststyle = 3
      vim.g.netrw_browse_split = 4
      vim.g.netrw_winsize = 25

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

      -- Highlight the symbol and its references when holding the cursor
      vim.api.nvim_create_autocmd('CursorHold', {
        pattern = '*',
        callback = function()
          vim.fn.CocActionAsync('highlight')
        end,
      })

      -- Symbol renaming
      vim.keymap.set('n', '<leader>rn', '<Plug>(coc-rename)', { silent = true })

      -- CoC Explorer
      vim.keymap.set('n', '<space>f', ':CocCommand explorer<CR>', { silent = true })

      -- Display settings
      vim.opt.colorcolumn = '79'
      vim.opt.hlsearch = true
      vim.opt.listchars = { tab = '  ', trail = '·', nbsp = '_' }
      vim.opt.list = true
      vim.opt.magic = true
      vim.opt.showmatch = true
      vim.opt.mat = 2
      vim.opt.background = 'dark'

      -- Terminal color support
      if vim.env.COLORTERM == 'gnome-terminal' then
        vim.opt.t_Co = 256
      end

      -- Encoding and file format
      vim.opt.encoding = 'utf8'
      vim.opt.fileformats = { 'unix', 'dos', 'mac' }

      -- Text, tab and indent settings
      vim.opt.expandtab = true
      vim.opt.smarttab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2
      vim.opt.autoindent = true
      vim.opt.smartindent = true
    '';
  };
}

