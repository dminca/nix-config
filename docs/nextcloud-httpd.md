# Nextcloud with httpd and Caddy as reverse-proxy

> Installer instructions for Nextcloud with httpd colocated on the same
host. Caddy runs on a different host acting as reverse-proxy for Nextcloud

- setting up httpd[^httpd]
- setting up PostgreSQL[^psql]
- setting up ~Redis~ Valkey[^cache]


[^httpd]: https://github.com/NixOS/nixpkgs/blob/205fd4226592cc83fd4c0885a3e4c9c400efabb5/nixos/modules/services/web-apps/nextcloud.md#using-an-alternative-webserver-as-reverse-proxy-eg-httpd-module-services-nextcloud-httpd
[^psql]: https://mich-murphy.com/configure-nextcloud-nixos/
[^cache]: https://github.com/grapefruit89/mynixos-v5/blob/59491f81db2844de87563b209a8870c0450834d2/modules/services/valkey.nix

