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
      ensureDatabases = [ "nextcloud" ];
      ensureUsers = [{
        name = "nextcloud";
        ensureDBOwnership = true;
      }];
    };
  };
  services.redis.package = pkgs.valkey;
  sops.secrets.nextcloud = {
    sopsFile = ./secrets/nextcloud.yaml;
    key = "password";
    owner = "nextcloud";
    group = "nextcloud";
  };
}
