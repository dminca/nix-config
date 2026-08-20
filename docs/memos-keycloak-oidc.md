# Memos + Keycloak OIDC

## Status: NOT IMPLEMENTED

Memos deployment-managed configuration via `/etc/secrets/` files requires read access to `/etc` within the service sandbox. The NixOS Memos module uses `ProtectSystem = "strict"` which makes overriding this permission complex and fragile.

**Current approach**: Memos runs with password-only authentication. OIDC integration can be revisited if:
1. Memos provides environment variable configuration for OIDC (simpler than file-based)
2. The NixOS module adds explicit support for `/etc/secrets/` access
3. A different deployment method (Docker, manual) is used that doesn't have sandbox restrictions

