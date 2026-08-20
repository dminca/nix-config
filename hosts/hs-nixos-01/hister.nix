{
  pkgs,
  inputs,
  ...
}:
let
  unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
in
{
  homelab.postgresql = {
    enable = true;
    profile = "small";
    settings.unix_socket_directories = "/run/postgresql";
    ensureDatabases = [ "hister" ];
    ensureUsers = [
      {
        name = "hister";
        ensureDBOwnership = true;
      }
    ];
  };

  services.hister = {
    enable = true;
    package = unstablePkgs.hister;
    dataDir = "/mnt/appdata";
    port = 4433;
    openFirewall = true;
    settings = {
      app = {
        log_level = "info";
        search_url = "https://google.com/search?q={query}";
        open_results_on_new_tab = true;
      };
      server = {
        address = "0.0.0.0:4433";
        base_url = "https://search.mrbl.dedyn.io";
        database = "host=/run/postgresql user=hister dbname=hister sslmode=disable";
      };
    };
  };

  systemd.services.hister = {
    after = [ "postgresql.service" ];
    wants = [ "postgresql.service" ];
  };
}
