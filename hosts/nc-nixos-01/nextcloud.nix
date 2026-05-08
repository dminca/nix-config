{
  pkgs,
  config,
  ...
}:
{
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx.enable = false;
  environment.etc."nextcloud-admin-pass".text = "imateapotq1w2e3";
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;
    hostName = "localhost";
    database.createLocally = true;
    caching = {
      redis = true;
    };
    configureRedis = false;
    config = {
      dbtype = "pgsql";
      dbname = "nextcloud";
      dbuser = "nextcloud";
      adminpassFile = "/etc/nextcloud-admin-pass";
      dbhost = "/run/postgresql";
      adminuser = "admin";
    };
    settings = {
      trusted_domains = [
        "nc.mrbl.dedyn.io"
        "localhost"
      ];
      default_phone_region = "DE";
    };
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) news contacts calendar tasks;
    };
    extraAppsEnable = true;
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
        ensureDBOwnership = true;
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

  # ensure postgresql and valkey are started before nextcloud
  systemd.services.nextcloud-setup = {
    requires = [ "postgresql.service" "redis-valkey.service" ];
    after = [ "postgresql.service" "redis-valkey.service" ];
    postStart = ''
      ${pkgs.nextcloud33}/bin/nextcloud-occ config:app:set redis host --value='/run/redis-valkey/redis.sock' || true
      ${pkgs.nextcloud33}/bin/nextcloud-occ config:app:set redis port --value='0' || true
    '';
  };
  #sops.secrets.nextcloud = {
  #  sopsFile = ./secrets/nextcloud.yaml;
  #  key = "password";
  #  owner = "nextcloud";
  #  group = "nextcloud";
  #};
}
