{
  lib,
  ...
}:
{
  programs.neovim = {
    extraLuaConfig = ''
      vim.cmd.colorscheme('zaibatsu')
    '';
  };
}
