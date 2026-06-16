{ config, ... }:
{
  sops.secrets.onlyofficeNonce = {
    sopsFile = ./secrets/nextcloud.yaml;
    key = "onlyofficeNonce";
    owner = "root";
    group = "onlyoffice";
    mode = "0440";
  };
  sops.secrets.onlyofficeJwt = {
    sopsFile = ./secrets/nextcloud.yaml;
    key = "onlyofficeJwt";
    owner = "root";
    group = "onlyoffice";
    mode = "0440";
  };
  services.onlyoffice = {
    enable = true;
    hostname = "office.mrbl.dedyn.io";
    postgresHost = "/run/postgresql";
    postgresName = "onlyoffice";
    postgresUser = "onlyoffice";
    securityNonceFile = config.sops.secrets.onlyofficeNonce.path;
    jwtSecretFile = config.sops.secrets.onlyofficeNonce.path;
    wopi = true;
    allowLocalConnections = true;
  };
}
