{
  config,
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
    globalConfig = ''
      acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
      acme_dns desec {
        auth_uri https://desec.io/api/v1/
        credentials {env.DESEC_API_TOKEN}
      }
    '';
    environmentFile = config.sops.secrets."desec_env".path;
    virtualHosts = {
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
      "office.mrbl.dedyn.io" = {
        extraConfig = ''
          log {
            output stderr
            format json
          }

          # The OnlyOffice doc server's bundled nginx overwrites
          # X-Forwarded-Proto with its own $scheme (http on the Caddy->nginx
          # hop), so it emits http:// cache URLs (e.g. Editor.bin). The editor
          # is loaded over https, so those become blocked mixed content
          # ("Download failed"). Tell the browser to upgrade same-origin
          # http sub-requests to https; Caddy serves them over TLS normally.
          header +Content-Security-Policy "upgrade-insecure-requests"

          reverse_proxy 10.10.10.156 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Host {host}
            header_up X-Forwarded-Proto {scheme}
            # Keep websocket traffic unbuffered through the edge proxy.
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
    };
  };
}
