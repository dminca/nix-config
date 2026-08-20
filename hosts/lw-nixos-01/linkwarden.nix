{
  config,
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
    owner = config.services.linkwarden.user;
  };

  sops.secrets.linkwarden-keycloak = {
    sopsFile = ./secrets/linkwarden.yaml;
    key = "KEYCLOAK_CLIENT_SECRET";
    owner = config.services.linkwarden.user;
  };

  # ── PostgreSQL ────────────────────────────────────────────────────────────
  homelab.postgresql = {
    enable = true;
    dataDir = "/mnt/appdata/postgresql";
    profile = "small";
    ensureDatabases = [ "linkwarden" ];
    ensureUsers = [
      {
        name = "linkwarden";
        ensureDBOwnership = true;
      }
    ];
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
      NEXT_PUBLIC_KEYCLOAK_ENABLED = "true";
      KEYCLOAK_ISSUER = "https://kc.mrbl.dedyn.io/realms/home";
      KEYCLOAK_CLIENT_ID = "linkwarden";
    };
    secretFiles = {
      NEXTAUTH_SECRET = config.sops.secrets.linkwarden.path;
      KEYCLOAK_CLIENT_SECRET = config.sops.secrets.linkwarden-keycloak.path;
    };
  };

}
