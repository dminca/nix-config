{
  lib,
  ...
}:
{
  programs.neovim = {
    extraConfig = lib.fileContents ./dotfiles/init.vim;
  };
}

