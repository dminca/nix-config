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
    plugins = with pkgs.vimPlugins; [
      vim-nix
      ctrlp-vim
      vim-gitgutter
      nnn-vim
    ];
  };
}
