{
  pkgs,
  lib,
  ...
}:
{
  plugins = {
    lsp.servers.tofu_ls.enable = true;
    conform-nvim.settings = {
      formatters_by_ft.terraform = [ "tofu" ];
      formatters.tofu_fmt = {
        command = lib.getExe pkgs.opentofu;
        args = [ "fmt" ];
      };
    };
  };
}
