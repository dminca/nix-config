{ config, ... }:
{
  sops.secrets."rss-oidc-client-secret" = {
    sopsFile = ./secrets/rss-oidc.yaml;
    key = "oauth2_proxy_client_secret";
    owner = "oauth2-proxy";
    group = "oauth2-proxy";
    mode = "0400";
  };

  sops.secrets."rss-oidc-cookie-secret" = {
    sopsFile = ./secrets/rss-oidc.yaml;
    key = "oauth2_proxy_cookie_secret";
    owner = "oauth2-proxy";
    group = "oauth2-proxy";
    mode = "0400";
  };

  services.oauth2-proxy = {
    enable = true;
    provider = "keycloak-oidc";
    clientID = "freshrss";
    clientSecretFile = config.sops.secrets."rss-oidc-client-secret".path;
    cookie.secretFile = config.sops.secrets."rss-oidc-cookie-secret".path;
    redirectURL = "https://rss.mrbl.dedyn.io/oauth2/callback";
    oidcIssuerUrl = "https://kc.mrbl.dedyn.io/realms/home";
    email.domains = [ "*" ];
    scope = "openid profile email";
    upstream = [ "static://202" ];
    reverseProxy = true;
    setXauthrequest = true;
    extraConfig = {
      skip-provider-button = true;
      whitelist-domain = ".mrbl.dedyn.io";
      user-id-claim = "preferred_username";
      insecure-oidc-allow-unverified-email = true;
    };
  };
}
