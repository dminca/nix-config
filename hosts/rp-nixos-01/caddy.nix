{
  config,
  ...
}:
{
  sops.secrets."fullchain.pem" = {
    sopsFile = ./secrets/certs.yaml;
    key = "fullchain";
    owner = "caddy";
    group = "caddy";
  };
  sops.secrets."privkey.pem" = {
    sopsFile = ./secrets/certs.yaml;
    key = "privkey";
    owner = "caddy";
    group = "caddy";
  };

  # Contains:
  # OAUTH2_PROXY_CLIENT_SECRET=...
  # OAUTH2_PROXY_COOKIE_SECRET=...   # 32-byte base64 value
  sops.secrets.oauth2-proxy-env = {
    sopsFile = ./secrets/example.yaml;
    key = "oauth2_proxy_env";
    owner = "oauth2-proxy";
    group = "oauth2-proxy";
    mode = "0400";
  };

  services.oauth2-proxy = {
    enable = true;
    provider = "keycloak-oidc";
    httpAddress = "http://127.0.0.1:4180";
    reverseProxy = true;
    keyFile = config.sops.secrets.oauth2-proxy-env.path;

    clientID = "home-assistant";
    oidcIssuerUrl = "https://kc.mrbl.dedyn.io/realms/home";
    redirectURL = "https://ha.mrbl.dedyn.io/oauth2/callback";
    email.domains = [ "*" ];
    scope = "openid profile email";

    # oauth2-proxy will authenticate with Keycloak, then proxy to Home Assistant.
    upstream = [ "http://10.10.10.181:8123" ];
  };

  services.caddy = {
    enable = true;
    virtualHosts = {
      "fw.mrbl.dedyn.io" = {
        extraConfig = ''
          tls ${config.sops.secrets."fullchain.pem".path} \
              ${config.sops.secrets."privkey.pem".path}

          reverse_proxy 192.168.178.3
        '';
      };
      "dns.mrbl.dedyn.io" = {
        extraConfig = ''
          tls ${config.sops.secrets."fullchain.pem".path} \
              ${config.sops.secrets."privkey.pem".path}

          reverse_proxy 192.168.178.2
        '';
      };
      "nc.mrbl.dedyn.io" = {
        extraConfig = ''
          tls ${config.sops.secrets."fullchain.pem".path} \
              ${config.sops.secrets."privkey.pem".path}

          reverse_proxy 10.10.10.156 {
            header_up X-Real-IP {remote_host}
          }
        '';
      };
      "office.mrbl.dedyn.io" = {
        extraConfig = ''
          tls ${config.sops.secrets."fullchain.pem".path} \
              ${config.sops.secrets."privkey.pem".path}

          reverse_proxy 10.10.10.156:9980 {
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
            # Required for WOPI: disable response buffering so WebSocket
            # frames and streaming document content flow through immediately
            flush_interval -1
            transport http {
              read_timeout  1h
              write_timeout 1h
            }
          }
        '';
      };
      "kc.mrbl.dedyn.io" = {
        extraConfig = ''
          tls ${config.sops.secrets."fullchain.pem".path} \
              ${config.sops.secrets."privkey.pem".path}

          reverse_proxy 10.10.10.118 {
              header_up Host {host}
              header_up X-Real-IP {remote}
              header_up X-Forwarded-Port {http.request.port}
          }
        '';
      };
      "ha.mrbl.dedyn.io" = {
        extraConfig = ''
          tls ${config.sops.secrets."fullchain.pem".path} \
              ${config.sops.secrets."privkey.pem".path}

          reverse_proxy 127.0.0.1:4180 {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };
      "pve.mrbl.dedyn.io" = {
        extraConfig = ''
          tls ${config.sops.secrets."fullchain.pem".path} \
              ${config.sops.secrets."privkey.pem".path}

          reverse_proxy https://192.168.178.16:8006 {
              transport http {
                  tls_insecure_skip_verify
              }
          }
        '';
      };
    };
  };
}
