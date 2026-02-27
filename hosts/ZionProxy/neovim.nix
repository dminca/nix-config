{
  pkgs,
  ...
}:
{
  programs.neovim = {
    plugins = [pkgs.vimPlugins.mini-indentscope];
    initLua = ''
      vim.cmd.colorscheme('zaibatsu')
      ---
      local MiniIndentscope = require('mini.indentscope')
      MiniIndentscope.setup(
      {
        draw = { delay = 0 },

        options = {
          indent_at_cursor = true,
      },
      symbol = '│',
      })
    '';
  };
}
