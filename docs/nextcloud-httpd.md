# Nextcloud with httpd Behind Caddy

Diataxis type: Explanation

This page explains the deployment model where Nextcloud runs with `httpd` on its host while Caddy runs on a separate reverse-proxy host.

## Architecture

- Nextcloud host serves the application via `httpd`.
- Reverse-proxy host (Caddy) terminates public TLS and forwards traffic to Nextcloud.
- PostgreSQL stores application data.
- Valkey is used for cache/session-style acceleration.

## Why this model

- Separates edge concerns (TLS, public routing) from app host concerns.
- Allows central ingress policy in Caddy.
- Keeps Nextcloud host focused on app and data services.

## References

- Nextcloud with alternative webserver in NixOS module docs: [httpd setup reference][httpd]
- Nextcloud + PostgreSQL example: [postgres setup reference][psql]
- Valkey module example: [valkey setup reference][cache]

[httpd]: https://github.com/NixOS/nixpkgs/blob/205fd4226592cc83fd4c0885a3e4c9c400efabb5/nixos/modules/services/web-apps/nextcloud.md#using-an-alternative-webserver-as-reverse-proxy-eg-httpd-module-services-nextcloud-httpd
[psql]: https://mich-murphy.com/configure-nextcloud-nixos/
[cache]: https://github.com/grapefruit89/mynixos-v5/blob/59491f81db2844de87563b209a8870c0450834d2/modules/services/valkey.nix

