{
  config,
  lib,
  pkgs,
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
  services.valkey = {
    enable = true;
    package = pkgs.valkey;
    port = 0; # Disable TCP port
    bind = ""; # Don't bind to any TCP address
    unixSocket = "/run/valkey/valkey.sock";
    unixSocketPerm = "755";
    dir = "/mnt/appdata/valkey";
    persistence = "aof";
  };

  # ── Meilisearch ───────────────────────────────────────────────────────────
  services.meilisearch = {
    enable = true;
    package = pkgs.meilisearch;
    listenAddress = "127.0.0.1";
    listenPort = 7700;
    environment = "production";
    dataDir = "/mnt/appdata/meilisearch";
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
      passwordFile = config.sops.secrets."linkwarden-db-password".path;
      socket = "/run/postgresql";
    };
    redis = {
      createLocally = false;
      url = "unix:/run/valkey/valkey.sock";
    };
    search = {
      meilisearch = {
        createLocally = false;
        host = "http://127.0.0.1:7700";
      };
    };
  };

  # ── Ensure data directories exist ─────────────────────────────────────────
  systemd.tmpfiles.rules = [
    "d /mnt/appdata 0755 root root -"
    "d /mnt/appdata/postgresql 0700 postgres postgres -"
    "d /mnt/appdata/valkey 0700 valkey valkey -"
    "d /mnt/appdata/meilisearch 0755 meilisearch meilisearch -"
  ];
}
