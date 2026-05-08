{
  pkgs,
  config,
  ...
}:
{
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx.enable = false;
  services.redis.package = pkgs.valkey;
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;
    hostName = "nc.mrbl.dedyn.io";
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
    virtualHosts."nc.mrbl.dedyn.io" = {
      documentRoot = config.services.nextcloud.package;
      serverAliases = [ "localhost" ];
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
  sops.secrets.nextcloud = {
    sopsFile = ./secrets/nextcloud.yaml;
    key = "password";
    owner = "nextcloud";
    group = "nextcloud";
  };
}
