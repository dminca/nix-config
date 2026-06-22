{ pkgs, config, ... }:
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
  # Same JWT secret, readable by the nextcloud user so the occ config
  # service can hand it to the ONLYOFFICE app (must match the doc server).
  sops.secrets.onlyofficeJwtNextcloud = {
    sopsFile = ./secrets/nextcloud.yaml;
    key = "onlyofficeJwt";
    owner = "nextcloud";
    group = "nextcloud";
    mode = "0400";
  };
  services.onlyoffice = {
    enable = true;
    hostname = "office.mrbl.dedyn.io";
    postgresHost = "/run/postgresql";
    postgresName = "onlyoffice";
    postgresUser = "onlyoffice";
    securityNonceFile = config.sops.secrets.onlyofficeNonce.path;
    jwtSecretFile = config.sops.secrets.onlyofficeJwt.path;
    # WOPI mode is finicky with the Nextcloud connector; use the classic
    # JWT-based integration which is the reliable, well-supported path.
    wopi = false;
    allowLocalConnections = true;
    loglevel = "WARN";
  };

  # Ensure onlyoffice services wait for sops to decrypt the nonce file
  systemd.services.onlyoffice-docservice = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };
  systemd.services.onlyoffice-converter = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };

  # Runs once after nextcloud-setup; idempotent (occ config/app commands are safe to re-run).
  systemd.services.nextcloud-onlyoffice-config = {
    description = "Configure Nextcloud ONLYOFFICE app";
    after = [
      "nextcloud-setup.service"
      "sops-nix.service"
    ];
    requires = [ "nextcloud-setup.service" ];
    wants = [ "sops-nix.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "nextcloud";
      RemainAfterExit = true;
      ExecStart = pkgs.writeScript "configure-onlyoffice" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        jwt_secret="$(cat ${config.sops.secrets.onlyofficeJwtNextcloud.path})"
        /run/current-system/sw/bin/nextcloud-occ app:disable richdocuments || true
        /run/current-system/sw/bin/nextcloud-occ app:enable onlyoffice
        /run/current-system/sw/bin/nextcloud-occ config:app:set onlyoffice DocumentServerUrl \
          --value="https://office.mrbl.dedyn.io/"
        /run/current-system/sw/bin/nextcloud-occ config:app:set onlyoffice DocumentServerInternalUrl \
          --value="https://office.mrbl.dedyn.io/"
        /run/current-system/sw/bin/nextcloud-occ config:app:set onlyoffice StorageUrl \
          --value="https://nc.mrbl.dedyn.io/"
        # JWT secret must match the document server's jwtSecretFile, otherwise
        # every editor request is rejected and documents fail to open.
        /run/current-system/sw/bin/nextcloud-occ config:app:set onlyoffice jwt_secret \
          --value="$jwt_secret"
        /run/current-system/sw/bin/nextcloud-occ config:app:set onlyoffice jwt_header \
          --value="Authorization"
      '';
    };
  };
}
