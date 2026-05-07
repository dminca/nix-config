{
  pkgs,
  config,
  ...
}:
{
  services.nginx.enable = false;
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;
    hostName = "localhost";
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
      defaultPhoneRegion = "DE";
    };
    settings = {
      trusted_domains = [
        "nc.mrbl.dedyn.io"
        "localhost"
      ];
    };
  };
  services.httpd = {
    enable = true;
    adminAddr = "webmaster@localhost";
    extraModules = [ "proxy_fcgi" ];
    virtualHosts."localhost" = {
      documentRoot = config.services.nextcloud.package;
      extraConfig = ''
        <Directory "${config.services.nextcloud.package}">
          <FilesMatch "\.php$">
            <If "-f %{REQUEST_FILENAME}">
              SetHandler "proxy:unix:${config.services.phpfpm.pools.nextcloud.socket}|fcgi://localhost/"
            </If>
          </FilesMatch>
          <IfModule mod_rewrite.c>
            RewriteEngine On
            RewriteBase /
            RewriteRule ^index\.php$ - [L]
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteRule . /index.php [L]
          </IfModule>
          DirectoryIndex index.php
          Require all granted
          Options +FollowSymLinks
        </Directory>
      '';
    };
  };
  services.phpfpm.pools.nextcloud.settings = {
    "listen.owner" = config.services.httpd.user;
    "listen.group" = config.services.httpd.group;
  };
  services = {
    postgresql = {
      enable = true;
      ensureDatabases = [ "nextcloud" ];
      ensureUsers = [{
        name = "nextcloud";
        ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
      }];
    };
  };
  services.redis.package = pkgs.valkey;
  services.redis.servers.valkey = {
    enable = true; 
    bind = ""; 
    port = 0; 
    openFirewall = false;
    settings = {
      maxmemory = "512mb"; maxmemory-policy = "allkeys-lru";
      save = [ "900 1" "300 10" "60 10000" ];
      unixsocket = "/run/redis-valkey/redis.sock"; 
      unixsocketperm = "770";
    };
  };
  systemd.services.redis-valkey.serviceConfig = {
    ProtectSystem = "strict"; ProtectHome = true; PrivateTmp = true; PrivateDevices = true; NoNewPrivileges = true;
    # 🛡️ KERNEL-LEVEL ISOLATION: No network access needed for local sockets
    PrivateNetwork = true;
    MemoryDenyWriteExecute = true; 
    RestrictAddressFamilies = [ "AF_UNIX" ]; 
    OOMScoreAdjust = -500;
  };

  # ensure postgresql db and valkey is started with nextcloud
  systemd = {
    services."nextcloud-setup" = {
      requires = [ "postgresql.service" "redis-valkey.service" ];
      after = [ "postgresql.service" "redis-valkey.service"];
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
