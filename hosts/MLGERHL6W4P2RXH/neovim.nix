{
  lib,
  pkgs,
  ...
}:
{
  programs.neovim = {
    extraConfig = lib.fileContents ./dotfiles/init.vim;
    coc = {
      settings = {
        languageserver = {
          helm = {
            command = lib.getExe pkgs.helm-ls;
            args = ["serve"];
            filetypes = ["helm" "helmfile"];
            rootPatterns = ["Chart.yaml"];
          };
          jsonnet = {
            command = lib.getExe pkgs.jsonnet-language-server;
            args = ["-t"];
            rootPatterns = [".git/" "jsonnetfile.json"];
            filetypes = ["jsonnet" "libsonnet"];
          };
        };
      };
    };
  };
}

