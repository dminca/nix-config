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

  services.caddy = {
    enable = true;
    virtualHosts = {
      "fw.mrbl.dedyn.io" = {
        extraConfig = ''
          tls ${config.sops.secrets."fullchain.pem".path} \
              ${config.sops.secrets."privkey.pem".path}

          log {
            output stderr
            format json
          }

          reverse_proxy 192.168.178.3
        '';
      };
      "dns.mrbl.dedyn.io" = {
        extraConfig = ''
          tls ${config.sops.secrets."fullchain.pem".path} \
              ${config.sops.secrets."privkey.pem".path}

          log {
            output stderr
            format json
          }

          reverse_proxy 192.168.178.2
        '';
      };
      "nc.mrbl.dedyn.io" = {
        extraConfig = ''
          tls ${config.sops.secrets."fullchain.pem".path} \
              ${config.sops.secrets."privkey.pem".path}

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
          tls ${config.sops.secrets."fullchain.pem".path} \
              ${config.sops.secrets."privkey.pem".path}

          log {
            output stderr
            format json
          }

          reverse_proxy 10.10.10.156 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Host {host}
            header_up X-Forwarded-Proto {scheme}
            # Keep WOPI and websocket traffic unbuffered through the edge proxy.
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
          tls ${config.sops.secrets."fullchain.pem".path} \
              ${config.sops.secrets."privkey.pem".path}

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
          tls ${config.sops.secrets."fullchain.pem".path} \
              ${config.sops.secrets."privkey.pem".path}

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
          tls ${config.sops.secrets."fullchain.pem".path} \
              ${config.sops.secrets."privkey.pem".path}

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
          tls ${config.sops.secrets."fullchain.pem".path} \
              ${config.sops.secrets."privkey.pem".path}

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
