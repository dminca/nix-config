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
    coc = {
      settings = {
        languageserver = {
          helm = {
            command = "helm_ls";
            args = ["serve"];
            filetypes = ["helm" "helmfile"];
            rootPatterns = ["Chart.yaml"];
          };
        };
      };
    };
  };
}

