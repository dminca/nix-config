{
  config,
  lib,
  ...
}:
{
  networking.firewall.allowedTCPPorts = [ 80 ];

  homelab.postgresql = {
    enable = true;
    profile = "small";
    dataDir = "/mnt/postgresql-data/pgdata";
    settings.unix_socket_directories = "/run/postgresql";
    ensureDatabases = [ "freshrss" ];
    ensureUsers = [
      {
        name = "freshrss";
        ensureDBOwnership = true;
      }
    ];
  };

  services.freshrss = {
    enable = true;
    baseUrl = "https://rss.mrbl.dedyn.io";
    virtualHost = "rss.mrbl.dedyn.io";
    dataDir = "/mnt/appdata/freshrss";
    authType = "http_auth";
    defaultUser = "admin";
    database = {
      type = "pgsql";
      host = "/run/postgresql";
      user = "freshrss";
      name = "freshrss";
    };
  };

  # FreshRSS accepts Remote-User/X-WebAuth-User only from trusted proxies.
  services.phpfpm.pools.freshrss.phpEnv.TRUSTED_PROXY = "10.10.10.135/32";

  systemd.services.freshrss-config = {
    requires = [ "postgresql.target" ];
    after = [ "postgresql.target" ];
    preStart = ''
      cat > "${config.services.freshrss.dataDir}/config.custom.php" <<'EOF'
      <?php
      return [
        'trusted_sources' => [ '10.10.10.135/32' ],
        'http_auth_auto_register' => true,
      ];
      EOF
    '';
  };

  # In http_auth mode, ensure the default user exists so context init does not fail.
  systemd.services.freshrss-http-auth-bootstrap = {
    description = "Ensure FreshRSS default user exists for http_auth";
    wantedBy = [ "multi-user.target" ];
    requires = [ "freshrss-config.service" ];
    after = [ "freshrss-config.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = config.services.freshrss.user;
      Group = config.users.users.${config.services.freshrss.user}.group;
      WorkingDirectory = config.services.freshrss.package;
      ReadWritePaths = [ config.services.freshrss.dataDir ];
    };
    environment.DATA_PATH = config.services.freshrss.dataDir;
    script = ''
      user_config="${config.services.freshrss.dataDir}/users/${config.services.freshrss.defaultUser}/config.php"
      if [ ! -f "$user_config" ]; then
        ./cli/create-user.php \
          --user ${lib.escapeShellArg config.services.freshrss.defaultUser} \
          --password 'unused-http-auth-password'
      fi
    '';
  };
}
