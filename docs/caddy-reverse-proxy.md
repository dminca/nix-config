# Caddy - reverse proxy

> the setup for Caddy reverse proxy for entire net

```
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
pve.mrbl.dedyn.io {
    import wildcard

    reverse_proxy https://192.168.178.16:8006 {
        transport http {
            tls_insecure_skip_verify
        }
    }
}
```
