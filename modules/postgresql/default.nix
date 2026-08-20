{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.postgresql;
  profiles = {
    small = {
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

    large = {
      max_connections = 500;
      max_wal_senders = 16;
      max_locks_per_transaction = 1024;
      shared_buffers = "512MB";
      wal_keep_size = "4GB";
      archive_timeout = 300;
      max_wal_size = "16GB";
      min_wal_size = "1GB";
    };
  };
in
{
  options.homelab.postgresql = {
    enable = lib.mkEnableOption "Shared PostgreSQL configuration for homelab hosts";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/postgresql-data/pgdata";
      description = "PostgreSQL data directory.";
    };

    profile = lib.mkOption {
      type = lib.types.enum [
        "small"
        "large"
        "custom"
      ];
      default = "small";
      description = "Settings profile used for services.postgresql.settings.";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra settings merged on top of the selected profile (or full settings for custom).";
    };

    ensureDatabases = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "Databases to create and ensure exist.";
    };

    ensureUsers = lib.mkOption {
      type = with lib.types; listOf attrs;
      default = [ ];
      description = "Users to create and ensure exist.";
    };

    createDataDir = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to create dataDir with systemd tmpfiles.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      dataDir = cfg.dataDir;
      ensureDatabases = cfg.ensureDatabases;
      ensureUsers = cfg.ensureUsers;
      settings = (if cfg.profile == "custom" then { } else profiles.${cfg.profile}) // cfg.settings;
    };

    systemd.tmpfiles.rules = lib.optional cfg.createDataDir "d ${cfg.dataDir} 0700 postgres postgres -";
  };
}
