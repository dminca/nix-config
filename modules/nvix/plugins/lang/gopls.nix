{ lib, pkgs, ... }:
{
  plugins = {
    lsp.servers.gopls = {
      enable = true;
      settings = {
        gopls = {
          # Organize imports on save
          gofumpt = true;
          usePlaceholders = true;
          completeUnimported = true;
          semanticTokens = true;
          staticcheck = true;
        };
      };
    };
    conform-nvim.settings = {
      formatters_by_ft.go = [ "goimports" ];
      formatters.goimports = {
        command = lib.getExe' pkgs.gotools "goimports";
      };
    };
  };

  # Auto-format on save for Go files
  autoGroups.gopls_format = {
    clear = true;
  };
  autoCmd = [
    {
      group = "gopls_format";
      event = [ "BufWritePre" ];
      pattern = [ "*.go" ];
      callback.__raw = ''
        function()
          require('conform').format({ async = false })
        end
      '';
    }
  ];
}
