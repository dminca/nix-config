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

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
