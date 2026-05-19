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
    ];
  };

  sops.secrets.linkwarden = {
    sopsFile = ./secrets/linkwarden.yaml;
    key = "NEXTAUTH_SECRET";
    owner = config.services.linkwarden.user;
  };

  sops.secrets.linkwarden-keycloak = {
    sopsFile = ./secrets/linkwarden.yaml;
    key = "KEYCLOAK_CLIENT_SECRET";
    owner = config.services.linkwarden.user;
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
      NEXTAUTH_URL = "https://lw.mrbl.dedyn.io/api/v1/auth";
      BASE_URL = "https://lw.mrbl.dedyn.io";
      NEXT_PUBLIC_KEYCLOAK_ENABLED = "true";
      KEYCLOAK_ISSUER = "https://kc.mrbl.dedyn.io/realms/home";
      KEYCLOAK_CLIENT_ID = "linkwarden";
    };
    secretFiles = {
      NEXTAUTH_SECRET = config.sops.secrets.linkwarden.path;
      KEYCLOAK_CLIENT_SECRET = config.sops.secrets.linkwarden-keycloak.path;
    };
  };

  systemd.tmpfiles.rules = [
    "d /mnt/appdata/postgresql 0700 postgres postgres -"
  ];
}
