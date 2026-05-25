{
  config,
  pkgs,
  ...
}:
{
  networking.firewall.allowedTCPPorts = [ 2283 ];

  # Intel iGPU userspace stack for VA-API/QSV transcoding.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
      vpl-gpu-rt
      libvdpau-va-gl
    ];
  };

  services.postgresql = {
    enable = true;
    dataDir = "/mnt/postgresql-data/pgdata";
    ensureDatabases = [ "immich" ];
    ensureUsers = [
      {
        name = "immich";
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

  # Use Valkey as the Redis-compatible backend.
  services.redis.package = pkgs.valkey;

  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = 2283;
    openFirewall = false;

    settings.server.externalDomain = "https://ic.mrbl.dedyn.io";
    settings.oauth = {
      enabled = true;
      issuerUrl = "https://kc.mrbl.dedyn.io/realms/home";
      clientId = "immich";
      clientSecret._secret = config.sops.secrets.immich-keycloak.path;
      scope = "openid email profile";
      signingAlgorithm = "RS256";
      profileSigningAlgorithm = "none";
      tokenEndpointAuthMethod = "client_secret_post";
      autoRegister = true;
      autoLaunch = false;
      buttonText = "Sign in with Keycloak";
      storageLabelClaim = "preferred_username";
      roleClaim = "immich_role";
      storageQuotaClaim = "immich_quota";
      timeout = 30000;
    };

    mediaLocation = "/mnt/appdata/immich";
    accelerationDevices = [ "/dev/dri/renderD128" ];

    environment = {
      LIBVA_DRIVER_NAME = "iHD";
      IMMICH_LOG_LEVEL = "log";
    };

    database = {
      enable = true;
      createDB = true;
      name = "immich";
      user = "immich";
      host = "/run/postgresql";
      port = 5432;
    };

    redis = {
      enable = true;
      host = "/run/redis-immich/redis.sock";
      port = 0;
    };
  };

  # Keep Redis/Valkey persistence on the mounted appdata disk.
  fileSystems."/var/lib/redis-immich" = {
    device = "/mnt/postgresql-data/valkey";
    options = [ "bind" ];
  };

  systemd.tmpfiles.rules = [
    "d /mnt/postgresql-data/pgdata 0700 postgres postgres -"
    "d /mnt/appdata/immich 0700 immich immich -"
    "d /mnt/postgresql-data/valkey 0750 redis redis -"
  ];

  sops.secrets.immich-keycloak = {
    sopsFile = ./secrets/immich.yaml;
    key = "clientSecret";
    owner = "immich";
    group = "immich";
    mode = "0400";
  };
}
