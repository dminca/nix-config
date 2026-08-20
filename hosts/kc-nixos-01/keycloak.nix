{
  pkgs,
  config,
  ...
}:
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.keycloak = {
    enable = true;
    settings = {
      hostname = "kc.mrbl.dedyn.io";
      http-enabled = true;
      hostname-strict-https = false;
      proxy-headers = "xforwarded";
      hostname-strict = false;
      "http.relative-path" = "/";
      "spi-theme-cache-themes" = "false";
      "spi-theme-cache-templates" = "false";
      "http-cookie-same-site" = "Lax";
      "web-authn-passwordless-signup-friendly-name" = "Passkey";
      "web-authn-passwordless-signup-signup-flow" = "webauthn-signup";
    };
    database = {
      type = "postgresql";
      createLocally = true;
      host = "/run/postgresql";
      username = "keycloak";
      passwordFile = config.sops.secrets.keycloak.path;
    };
    plugins = with pkgs.keycloak.plugins; [
      junixsocket-common
      junixsocket-native-common
    ];
  };

  homelab.postgresql = {
    enable = true;
    profile = "large";
    ensureDatabases = [ "keycloak" ];
    ensureUsers = [
      {
        name = "keycloak";
        ensureDBOwnership = true;
      }
    ];
  };

  sops.secrets.keycloak = {
    sopsFile = ./secrets/keycloak.yaml;
    key = "password";
    mode = "0777";
  };
}
