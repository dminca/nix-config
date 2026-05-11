{
  pkgs,
  config,
  ...
}:
{
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx.enable = true;
  services.nextcloud = {
    enable = true;
    https = true;
    package = pkgs.nextcloud33;
    maxUploadSize = "1G";
    hostName = "nc.mrbl.dedyn.io";
    datadir = "/mnt/nextcloud-data/nextcloud";
    database.createLocally = true;
    caching = {
      redis = true;
    };
    configureRedis = true;
    config = {
      dbtype = "pgsql";
      dbname = "nextcloud";
      dbuser = "nextcloud";
      adminpassFile = config.sops.secrets.nextcloud.path;
      dbhost = "/run/postgresql";
      adminuser = "admin";
    };
    settings = {
      trusted_domains = [
        "nc.mrbl.dedyn.io"
        "localhost"
      ];
      trusted_proxies = [
        "10.10.10.135" # IP address of rp-nixos-01 (Caddy host)
      ];
      overwriteprotocol = "https";
      default_phone_region = "DE";
      maintenance_window_start = 0; # midnight UTC
      allow_local_remote_servers = true;
    };
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) news contacts calendar tasks user_oidc richdocuments;
    };
    extraAppsEnable = true;
    phpOptions = {
      "opcache.enable" = "1";
      "opcache.interned_strings_buffer" = "32";
      "opcache.max_accelerated_files" = "10000";
      "opcache.memory_consumption" = "256";
      "opcache.revalidate_freq" = "60";
      "opcache.save_comments" = "1";
      "opcache.jit" = "1255";
      "opcache.jit_buffer_size" = "128M";
    };
  };

  services.phpfpm.pools.nextcloud.settings = {
    "pm" = "dynamic";
    "pm.max_requests" = "500";
  };
  services = {
    postgresql = {
      enable = true;
      dataDir = "/mnt/postgresql-data/pgdata";
      ensureDatabases = [ "nextcloud" ];
      ensureUsers = [{
        name = "nextcloud";
        ensureDBOwnership = true;
      }];
      settings = {
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
  };
  services.redis.package = pkgs.valkey;

  # Run mimetype migrations once after each nextcloud-setup (idempotent)
  systemd.services.nextcloud-mimetype-migration = {
    description = "Nextcloud mimetype migration";
    after = [ "nextcloud-setup.service" ];
    requires = [ "nextcloud-setup.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "nextcloud";
      ExecStart = "/run/current-system/sw/bin/nextcloud-occ maintenance:repair --include-expensive";
      RemainAfterExit = true;
    };
  };

  sops.secrets.nextcloud = {
    sopsFile = ./secrets/nextcloud.yaml;
    key = "password";
    owner = "nextcloud";
    group = "nextcloud";
  };
  systemd.tmpfiles.rules = [
    "d /mnt/postgresql-data/pgdata 0700 postgres postgres -"
    "d /mnt/nextcloud-data/nextcloud 0700 nextcloud nextcloud -"
  ];
}
