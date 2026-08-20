{
  pkgs,
  inputs,
  ...
}:
let
  unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
in
{
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
    settings = {
      app.log_level = "info";
      server.address = "0.0.0.0:4433";
      server.base_url = "https://search.mrbl.dedyn.io";
      server.database = "host=/run/postgresql user=hister dbname=hister sslmode=disable";
    };
  };

  systemd.services.hister = {
    after = [ "postgresql.service" ];
    wants = [ "postgresql.service" ];
  };
}
