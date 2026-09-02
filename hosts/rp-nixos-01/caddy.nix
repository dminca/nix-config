{
  config,
  pkgs,
  ...
}:
{
  # Store deSEC API token as a sops secret in environment file format
  sops.secrets."desec_env" = {
    sopsFile = ./secrets/acme.yaml;
    key = "desec_env";
    owner = "caddy";
    group = "caddy";
    mode = "0400";
  };

  services.caddy = {
    enable = true;
    email = "admin@mrbl.dedyn.io";
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/desec@v1.1.0" ];
      hash = "sha256-/o/6Uw+HoZCLVRYE2/ymDtWT/AuQ/sxNGy0zVM+Wlco=";
    };
    globalConfig = ''
      acme_ca https://acme-v02.api.letsencrypt.org/directory
      acme_dns desec {
        token {env.DESEC_API_TOKEN}
      }
    '';
    virtualHosts = {
      "*.mrbl.dedyn.io" = {
        extraConfig = ''
          log {
            output stderr
            format json
          }
        '';
      };
      "fw.mrbl.dedyn.io" = {
        extraConfig = ''
          log {
            output stderr
            format json
          }

          reverse_proxy 192.168.178.3
        '';
      };
      "dns.mrbl.dedyn.io" = {
        extraConfig = ''
          log {
            output stderr
            format json
          }

          reverse_proxy 192.168.178.2
        '';
      };
      "nc.mrbl.dedyn.io" = {
        extraConfig = ''
          log {
            output stderr
            format json
          }

          reverse_proxy 10.10.10.156 {
            header_up X-Real-IP {remote_host}
          }
        '';
      };
      "kc.mrbl.dedyn.io" = {
        extraConfig = ''
          log {
            output stderr
            format json
          }

          reverse_proxy 10.10.10.118 {
              header_up Host {host}
              header_up X-Real-IP {remote}
              header_up X-Forwarded-Port {http.request.port}
          }
        '';
      };
      "lw.mrbl.dedyn.io" = {
        extraConfig = ''
          log {
            output stderr
            format json
          }

          reverse_proxy 10.10.10.153:3000 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
            header_up X-Forwarded-Host {host}
          }
        '';
      };
      "ic.mrbl.dedyn.io" = {
        extraConfig = ''
          log {
            output stderr
            format json
          }

          reverse_proxy 10.10.10.162:2283 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
            header_up X-Forwarded-Host {host}
          }
        '';
      };
      "mon.mrbl.dedyn.io" = {
        extraConfig = ''
          log {
            output stderr
            format json
          }

          reverse_proxy 10.10.10.187:3000 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
            header_up X-Forwarded-Host {host}
          }
        '';
      };
      "pve.mrbl.dedyn.io" = {
        extraConfig = ''
          log {
            output stderr
            format json
          }

          reverse_proxy https://192.168.178.16:8006 {
              transport http {
                  tls_insecure_skip_verify
              }
          }
        '';
      };
      "search.mrbl.dedyn.io" = {
        extraConfig = ''
          log {
            output stderr
            format json
          }

          reverse_proxy 10.10.10.157:4433 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
            header_up X-Forwarded-Host {host}
          }
        '';
      };
      "notes.mrbl.dedyn.io" = {
        extraConfig = ''
          log {
            output stderr
            format json
          }

          reverse_proxy 10.10.10.173:5230 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
            header_up X-Forwarded-Host {host}
          }
        '';
      };
      "rss.mrbl.dedyn.io" = {
        extraConfig = ''
          log {
            output stderr
            format json
          }

          @oauth2 path /oauth2/*
          handle @oauth2 {
            reverse_proxy 127.0.0.1:4180
          }

          @freshrss_api path /api/*
          handle @freshrss_api {
            reverse_proxy 10.10.10.136:80 {
              header_up Host {host}
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
              header_up X-Forwarded-Host {host}
            }
          }

          handle {
            forward_auth 127.0.0.1:4180 {
              uri /oauth2/auth
              copy_headers X-Auth-Request-User>X-WebAuth-User X-Auth-Request-Email>Remote-Email
              @unauth status 401
              handle_response @unauth {
                redir * /oauth2/start?rd={uri} 302
              }
            }

            reverse_proxy 10.10.10.136:80 {
              header_up Host {host}
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
              header_up X-Forwarded-Host {host}
            }
          }
        '';
      };
    };
  };

  # Override the caddy systemd service to include the environment file
  systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.secrets."desec_env".path;
}
