{
  pkgs,
  inputs,
  ...
}:
let
  unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
in
{
  services.postgresql = {
    enable = true;
    dataDir = "/mnt/postgresql-data/pgdata";
    settings = {
      unix_socket_directories = "/run/postgresql";
      max_connections = 200;
      shared_buffers = "256MB";
      effective_cache_size = "1GB";
      maintenance_work_mem = "64MB";
      checkpoint_completion_target = 0.9;
      wal_buffers = "16MB";
      default_statistics_target = 100;
      random_page_cost = 1.1;
      effective_io_concurrency = 200;
      work_mem = "1310kB";
      min_wal_size = "1GB";
      max_wal_size = "4GB";
    };
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
      app.log_level = "info";
      server.address = "0.0.0.0:4433";
      server.base_url = "https://search.mrbl.dedyn.io";
      server.database = "host=/run/postgresql user=hister dbname=hister sslmode=disable";
    };
  };

  systemd.services.hister = {
    after = [ "postgresql.service" ];
    wants = [ "postgresql.service" ];
  };

  systemd.tmpfiles.rules = [
    "d /mnt/postgresql-data/pgdata 0700 postgres postgres -"
  ];
}
