# Caddy Reverse Proxy Configuration

Diataxis type: Reference

This page is a reference Caddyfile used to route public hostnames to internal services.

## Caddyfile

```caddyfile
(wildcard) {
    tls /var/lib/caddy/certs/fullchain.pem \
        /var/lib/caddy/certs/privkey.pem
}

fw.mrbl.dedyn.io {
    import wildcard
    reverse_proxy 192.168.178.3
}

dns.mrbl.dedyn.io {
    import wildcard
    reverse_proxy 192.168.178.2
}

nc.mrbl.dedyn.io {
    import wildcard
    reverse_proxy 10.10.10.102
}

kc.mrbl.dedyn.io {
    import wildcard
    reverse_proxy 10.10.10.118 {
        header_up Host {host}
        header_up X-Real-IP {remote}
        header_up X-Forwarded-For {remote}
        header_up X-Forwarded-Proto {scheme}
        header_up X-Forwarded-Host {host}
        header_up X-Forwarded-Port {http.request.port}
    }
}

pve.mrbl.dedyn.io {
    import wildcard
    reverse_proxy https://192.168.178.16:8006 {
        transport http {
            tls_insecure_skip_verify
        }
    }
}
```

## Notes

- `wildcard` centralizes certificate paths for all sites.
- Keycloak forwards upstream proxy headers explicitly.
- Proxmox upstream uses TLS with certificate verification disabled.

## Related reading

- Caddy on NixOS setup: [homelab caddy reverse-proxy article][caddy]

[caddy]: https://aottr.dev/posts/2024/08/homelab-setting-up-caddy-reverse-proxy-with-ssl-on-nixos/

