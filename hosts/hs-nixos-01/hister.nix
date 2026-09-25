{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  sops.secrets."hister-oidc-client-secret" = {
    sopsFile = ./secrets/hister.yaml;
    key = "clientSecret";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.templates."hister-config.yml" = {
    content = ''
      app:
        log_level: info
        search_url: "https://google.com/search?q={query}"
        open_results_on_new_tab: true
        user_handling: true
      server:
        address: 0.0.0.0:4433
        base_url: https://search.mrbl.dedyn.io
        database: host=/run/postgresql user=hister dbname=hister sslmode=disable
        oauth_only: true
        oauth:
          oidc:
            client_id: hister
            client_secret: ${config.sops.placeholder."hister-oidc-client-secret"}
            configuration_url: https://kc.mrbl.dedyn.io/realms/home/.well-known/openid-configuration
            scopes:
              - openid
              - email
              - profile
    '';
    owner = "hister";
    group = "hister";
    mode = "0400";
  };

  # ── Technitium DNS "Query Logs (PostgreSQL)" app ─────────────────────────
  # Technitium (192.168.178.2) connects over TCP with a password; see
  # Obsidian/Memos docs for the SCRAM hash generation script and rationale.
  networking.firewall.allowedTCPPorts = [ 5432 ];

  services.postgresql.authentication = lib.mkAfter ''
    # Technitium DNS server (192.168.178.2) → technitium db, password auth only
    host  technitium  technitium  192.168.178.2/32  scram-sha-256
  '';

  homelab.postgresql = {
    enable = true;
    profile = "small";
    settings = {
      unix_socket_directories = "/run/postgresql";
      # Required for the Technitium host to reach this instance over TCP;
      # pg_hba above still restricts who's actually allowed to connect.
      listen_addresses = lib.mkForce "*";
    };
    ensureDatabases = [
      "hister"
      "technitium"
    ];
    ensureUsers = [
      {
        name = "hister";
        ensureDBOwnership = true;
      }
      {
        name = "technitium";
        ensureDBOwnership = true;
        ensureClauses.password = "SCRAM-SHA-256$4096:7E95iCGDg38nJK7d1yMv2w==$ifr8b2aZmXH9IqeNquHFg03C/av6AXKKLo5tp+9eQC4=:yTKbCivBCYpDHRgYUaTOyoCJcTWP/+SUZFSZWvea764=";
      }
    ];
  };

  # dns_logs is created lazily by Technitium's app on first log write, so this
  # runs on a timer (not just at boot) and uses IF EXISTS to no-op until then.
  systemd.services.technitium-postgres-tuning = {
    description = "Tune autovacuum on Technitium's dns_logs table";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      ExecStart = pkgs.writeShellScript "technitium-postgres-tuning" ''
        ${config.services.postgresql.package}/bin/psql -d technitium -c \
          "ALTER TABLE IF EXISTS dns_logs SET (autovacuum_vacuum_scale_factor = 0.02, autovacuum_vacuum_cost_delay = 10);"
      '';
    };
  };

  systemd.timers.technitium-postgres-tuning = {
    description = "Periodically (re-)apply Technitium dns_logs autovacuum tuning";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "1h";
    };
  };

  services.hister = {
    enable = true;
    package = unstablePkgs.hister;
    dataDir = "/mnt/appdata";
    port = 4433;
    openFirewall = true;
    configPath = config.sops.templates."hister-config.yml".path;
  };

  systemd.services.hister = {
    after = [ "postgresql.service" ];
    wants = [ "postgresql.service" ];
  };
}
