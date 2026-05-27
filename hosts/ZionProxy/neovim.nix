{
  ...
}:
{
  programs.neovim = {
    extraLuaConfig = ''
      vim.cmd.colorscheme('sorbet')
    '';
  };
}
