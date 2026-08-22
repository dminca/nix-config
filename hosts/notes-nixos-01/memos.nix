{
  lib,
  ...
}:
{
  networking.firewall.allowedTCPPorts = [ 5230 ];

  homelab.postgresql = {
    enable = true;
    profile = "small";
    dataDir = "/mnt/postgresql-data/pgdata";
    settings.unix_socket_directories = "/run/postgresql";
    ensureDatabases = [ "memos" ];
    ensureUsers = [
      {
        name = "memos";
        ensureDBOwnership = true;
      }
    ];
  };

  services.memos = {
    enable = true;
    openFirewall = false;
    dataDir = "/mnt/appdata/memos";
    settings = {
      MEMOS_PORT = "5230";
      MEMOS_DRIVER = "postgres";
      MEMOS_DSN = "postgres://memos@/memos?host=/run/postgresql&sslmode=disable";
      MEMOS_INSTANCE_URL = "https://notes.mrbl.dedyn.io";
    };
  };

  systemd.services.memos = {
    after = [ "postgresql.service" ];
    wants = [ "postgresql.service" ];
  };
}
