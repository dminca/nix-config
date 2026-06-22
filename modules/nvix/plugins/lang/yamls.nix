{ ... }:
{
  plugins = {
    lsp.servers.yamlls = {
      enable = true;
      settings = {
        yaml = {
          format.enable = true;
          validate = true;
          completion = true;
          hover = true;
          schemaStore = {
            # Use SchemaStore.org catalog for built-in schema detection
            enable = true;
            url = "https://www.schemastore.org/api/json/catalog.json";
          };
          # Auto-detects CRD schemas from apiVersion/kind in any YAML file,
          # including all FluxCD CRDs (HelmRelease, Kustomization, GitRepository, etc.)
          kubernetesCRDStore.enable = true;
          schemas = {
            kubernetes = "/*.yaml";
          };
        };
      };
    };
  };
}
