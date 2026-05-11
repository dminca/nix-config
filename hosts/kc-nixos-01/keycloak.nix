{
  pkgs,
  config,
  ...
}:
{
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  environment.etc."keycloak-database-pass".text = "PWD";
  services.keycloak = {
    enable = true;
    settings = {
      hostname = "kc.mrbl.dedyn.io";
      http-enabled = true;
      hostname-strict-https = false;
    };
    database.passwordFile = config.sops.secrets.keycloak.path;
  };

  services = {
    postgresql = {
      enable = true;
      dataDir = "/mnt/postgresql-data";
      ensureDatabases = [ "keycloak" ];
      ensureUsers = [{
        name = "keycloak";
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

  sops.secrets.keycloak = {
    sopsFile = ./secrets/keycloak.yaml;
    key = "password";
    owner = "keycloak";
    group = "keycloak";
  };
}
