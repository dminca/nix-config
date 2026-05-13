{
  pkgs,
  config,
  lib,
  ...
}:
{
  networking.firewall = {
    allowedTCPPorts = [
      80
      443
      3478
    ];
    allowedUDPPorts = [ 3478 ];
    allowedUDPPortRanges = [
      {
        from = 49152;
        to = 65535;
      }
    ];
  };
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
      hide_login_form = true;
    };
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        news
        contacts
        calendar
        tasks
        user_oidc
        richdocuments
        spreed
        ;
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
      ensureUsers = [
        {
          name = "nextcloud";
          ensureDBOwnership = true;
        }
      ];
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
  sops.secrets.coturn-secret = {
    sopsFile = ./secrets/nextcloud.yaml;
    key = "coturn_secret";
    owner = "root";
    group = "turnserver";
    mode = "0640";
  };
  systemd.tmpfiles.rules = [
    "d /mnt/postgresql-data/pgdata 0700 postgres postgres -"
    "d /mnt/nextcloud-data/nextcloud 0700 nextcloud nextcloud -"
  ];

  # Enable coturn only to get the turnserver user/group and package installed;
  # the actual config is generated at runtime so the secret never enters the Nix store.
  services.coturn.enable = true;

  systemd.services.coturn = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
    serviceConfig = {
      RuntimeDirectory = "coturn";
      ExecStartPre = [
        (pkgs.writeShellScript "coturn-config-gen" ''
                    secret=$(< ${config.sops.secrets.coturn-secret.path})
                    cat > /run/coturn/turnserver.conf <<EOF
          lt-cred-mech
          use-auth-secret
          static-auth-secret=$secret
          realm=nc.mrbl.dedyn.io
          no-tcp-relay
          min-port=49152
          max-port=65535
          no-multicast-peers
          no-cli
          no-tlsv1
          no-tlsv1_1
          EOF
        '')
      ];
      ExecStart = lib.mkForce "${pkgs.coturn}/bin/turnserver -c /run/coturn/turnserver.conf";
    };
  };
}
