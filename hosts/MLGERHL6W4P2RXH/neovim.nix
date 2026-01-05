{
  lib,
  pkgs,
  ...
}:
{
  # Host-specific neovim configuration for MLGERHL6W4P2RXH
  # Additional language servers for helm and jsonnet
  programs.neovim = {
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
            args = [
              "-t"
              "-J"
              "lib"
            ];
            rootPatterns = [".git/" "jsonnetfile.json"];
            filetypes = ["jsonnet" "libsonnet"];
          };
        };
      };
    };
    extraLuaConfig = ''
      vim.cmd.colorscheme('retrobox')
    '';
  };
}
