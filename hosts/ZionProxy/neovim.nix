{
  ...
}:
{
  programs.neovim = {
    extraLuaConfig = ''
      vim.cmd.colorscheme('torte')
    '';
  };
}
