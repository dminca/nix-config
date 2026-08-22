{
  config,
  pkgs,
  inputs,
  ...
}:
let
  unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
in
{
  sops.secrets."hister-oidc-client-secret" = {
    sopsFile = ./secrets/hister.yaml;
    key = "clientSecret";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.templates."hister-oidc.env" = {
    content = ''
      HISTER_SERVER__OAUTH__OIDC__CLIENT_SECRET=${config.sops.placeholder."hister-oidc-client-secret"}
    '';
    owner = "hister";
    group = "hister";
    mode = "0400";
  };

  homelab.postgresql = {
    enable = true;
    profile = "small";
    settings.unix_socket_directories = "/run/postgresql";
    ensureDatabases = [ "hister" ];
    ensureUsers = [
      {
        name = "hister";
        ensureDBOwnership = true;
      }
    ];
  };

  services.hister = {
    enable = true;
    package = unstablePkgs.hister;
    dataDir = "/mnt/appdata";
    port = 4433;
    openFirewall = true;
    environmentFile = config.sops.templates."hister-oidc.env".path;
    settings = {
      app = {
        log_level = "info";
        search_url = "https://google.com/search?q={query}";
        open_results_on_new_tab = true;
        user_handling = true;
      };
      server = {
        address = "0.0.0.0:4433";
        base_url = "https://search.mrbl.dedyn.io";
        database = "host=/run/postgresql user=hister dbname=hister sslmode=disable";
        oauth.oidc = {
          client_id = "hister";
          configuration_url = "https://kc.mrbl.dedyn.io/realms/home/.well-known/openid-configuration";
          scopes = [
            "openid"
            "email"
            "profile"
          ];
        };
      };
    };
  };

  systemd.services.hister = {
    after = [ "postgresql.service" ];
    wants = [ "postgresql.service" ];
  };
}
