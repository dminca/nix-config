{
  lib,
  ...
}:
{
  programs.neovim = {
    extraConfig = lib.fileContents ./dotfiles/init.vim;
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

