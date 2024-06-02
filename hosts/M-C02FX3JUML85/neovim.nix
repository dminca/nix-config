{
  lib,
  config,
  ...
}:
{
  programs.neovim = {
    extraConfig = builtins.concatStringsSep "\n" [
      "${lib.fileContents ./dotfiles/init.vim}"
      ''
        source ${config.sops.secrets.additionalNvimconfig.path}
      ''
    ];
  };
}

