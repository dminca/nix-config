{
  config,
  pkgs,
  lib,
  ...
}:
{
  # ── Networking ────────────────────────────────────────────────────────────
  networking.firewall = {
    allowedTCPPorts = [
      3000 # Linkwarden
    ];
  };

  sops.secrets.linkwarden = {
    sopsFile = ./secrets/linkwarden.yaml;
    key = "NEXTAUTH_SECRET";
  };

  # ── PostgreSQL ────────────────────────────────────────────────────────────
  services.postgresql = {
    enable = true;
    dataDir = "/mnt/appdata/postgresql";
    ensureDatabases = [ "linkwarden" ];
    ensureUsers = [
      {
        name = "linkwarden";
        ensureDBOwnership = true;
      }
    ];
    settings = {
      max_connections = 200;
      shared_buffers = "256MB";
      effective_cache_size = "1GB";
      maintenance_work_mem = "64MB";
      checkpoint_completion_target = 0.9;
      wal_buffers = "16MB";
      default_statistics_target = 100;
      random_page_cost = 1.1;
      effective_io_concurrency = 200;
      work_mem = "1310kB";
      min_wal_size = "1GB";
      max_wal_size = "4GB";
    };
  };

  # ── Linkwarden ────────────────────────────────────────────────────────────
  services.linkwarden = {
    enable = true;
    port = 3000;
    host = "0.0.0.0";
    openFirewall = false;
    database = {
      createLocally = true;
      name = "linkwarden";
      user = "linkwarden";
      host = "/run/postgresql";
    };
    environment = {
      NEXTAUTH_URL = "https://lw.mrbl.dedyn.io/api/v1/auth";
      BASE_URL = "https://lw.mrbl.dedyn.io";
    };
    secretFiles = {
      NEXTAUTH_SECRET = config.sops.secrets.linkwarden.path;
    };
  };

  # ── Ensure data directories exist on the mounted filesystem ──────────────
  # This oneshot service runs after mnt-appdata.mount and creates the required
  # directories directly on the mounted filesystem. Modifying the global
  # systemd-tmpfiles-setup with RequiresMountsFor would cause emergency mode
  # if the secondary disk fails to mount during early boot.
  systemd.services.lw-appdata-setup = {
    description = "Create /mnt/appdata directories for Linkwarden services";
    # Do NOT use wantedBy = ["multi-user.target"] here. If the mount is
    # restarted during nixos-rebuild switch, systemd would queue a stop for
    # this unit while also needing to start multi-user.target, producing a
    # "destructive transaction" error (nss-lookup.target conflict). Instead,
    # application services pull this unit in via their own wants/after.
    after = [ "mnt-appdata.mount" ];
    requires = [ "mnt-appdata.mount" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = [
        "${lib.getExe' pkgs.coreutils "install"} -d -m 0700 -o postgres -g postgres /mnt/appdata/postgresql"
      ];
    };
  };

  # PostgreSQL dataDir lives on /mnt/appdata — must not start before setup.
  systemd.services.postgresql = {
    wants = [ "lw-appdata-setup.service" ];
    after = [ "lw-appdata-setup.service" ];
  };

  systemd.services.linkwarden = {
    after = [
      "postgresql.service"
      "sops-nix.service"
    ];
    requires = [
      "postgresql.service"
    ];
  };
}
