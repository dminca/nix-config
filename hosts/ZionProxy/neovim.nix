{
  ...
}:
{
  programs.neovim = {
    initLua = ''
      vim.cmd.colorscheme('zaibatsu')
    '';
  };
}
