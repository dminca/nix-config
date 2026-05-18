{
  config,
  pkgs,
  lib,
  ...
}:
{
  # ── Networking ────────────────────────────────────────────────────────────
  networking.firewall = {
    allowedTCPPorts = [
      3000 # Linkwarden
      5432 # PostgreSQL (if remote access needed)
      7700 # Meilisearch (if remote access needed)
    ];
  };

  sops.secrets.linkwarden = {
    sopsFile = ./secrets/linkwarden.yaml;
    key = "NEXTAUTH_SECRET";
  };

  # ── PostgreSQL ────────────────────────────────────────────────────────────
  services.postgresql = {
    enable = true;
    dataDir = "/mnt/appdata/postgresql";
    ensureDatabases = [ "linkwarden" ];
    ensureUsers = [
      {
        name = "linkwarden";
        ensureDBOwnership = true;
      }
    ];
    settings = {
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
  };

  # ── Valkey (Redis alternative) ────────────────────────────────────────────
  services.redis = {
    enable = true;
    package = pkgs.valkey;
    port = 0; # Disable TCP port
    bind = ""; # Don't bind to any TCP address
    unixSocket = "/run/valkey/valkey.sock";
    unixSocketPerm = 755;
  };

  # ── Meilisearch ───────────────────────────────────────────────────────────
  services.meilisearch = {
    enable = true;
    listenAddress = "127.0.0.1";
    listenPort = 7700;
    settings = {
      db_path = "/mnt/appdata/meilisearch";
      env = "production";
    };
  };

  # ── Linkwarden ────────────────────────────────────────────────────────────
  services.linkwarden = {
    enable = true;
    port = 3000;
    host = "0.0.0.0";
    openFirewall = false;
    database = {
      createLocally = true;
      name = "linkwarden";
      user = "linkwarden";
      host = "/run/postgresql";
    };
    environment = {
      MEILI_HOST = "http://127.0.0.1:7700";
    };
    secretFiles = {
      NEXTAUTH_SECRET = config.sops.secrets.linkwarden.path;
    };
  };

  systemd.tmpfiles.rules = [
    "d /mnt/appdata/postgresql 0700 postgres postgres -"
    "d /mnt/appdata/meilisearch 0755 meilisearch meilisearch -"
  ];

  systemd.services.linkwarden = {
    after = [
      "postgresql.service"
      "redis.service" # services.redis (with package = pkgs.valkey) creates redis.service
      "meilisearch.service"
      "sops-nix.service"
    ];
    requires = [
      "postgresql.service"
      "redis.service"
      "meilisearch.service"
    ];
  };
}
