# Keycloak and Linkwarden OIDC Operations

Diataxis type: How-to guide

Use this guide to configure Keycloak for Linkwarden and to fix the common `OAuthAccountNotLinked` failure after reinstalls.

## Configure Keycloak client for Linkwarden

Create or verify a client in realm `home`.

### General

1. Client ID: `linkwarden`
2. Protocol: `openid-connect`
3. Enabled: on

### Capability settings

1. Client authentication: on
2. Authorization: off
3. Standard flow: on
4. Direct access grants: off
5. Implicit flow: off
6. Service accounts roles: off

### Login settings

1. Root URL: `https://lw.mrbl.dedyn.io`
2. Home URL: `https://lw.mrbl.dedyn.io`
3. Valid redirect URIs: `https://lw.mrbl.dedyn.io/api/v1/auth/callback/keycloak`
4. Valid post logout redirect URIs: `https://lw.mrbl.dedyn.io/*`
5. Web origins: `https://lw.mrbl.dedyn.io`
6. Consent required: off

### Apply credentials

1. Regenerate the client secret in Keycloak.
2. Store it in your encrypted secret as `KEYCLOAK_CLIENT_SECRET`.
3. Rebuild and restart Linkwarden:

```bash
sudo nixos-rebuild switch --flake .#lw-nixos-01
sudo systemctl restart linkwarden.service
```

### Validate quickly

```bash
curl -fsSL https://kc.mrbl.dedyn.io/realms/home/.well-known/openid-configuration | jq .issuer,.token_endpoint
```

Expected issuer:

- `https://kc.mrbl.dedyn.io/realms/home`

Check service logs after one login attempt:

```bash
sudo journalctl -u linkwarden.service -n 120 -e
```

## Resolve `OAuthAccountNotLinked`

This error means Keycloak authentication succeeded, but Linkwarden could not link the returned Keycloak identity to an existing local account.

### 1. Back up the Linkwarden database

```bash
sudo -u postgres pg_dump linkwarden > /tmp/linkwarden-before-account-link.sql
```

### 2. Inspect the user and linked auth records

```bash
sudo -u postgres psql linkwarden
```

```sql
\dt
SELECT id, email FROM "User" WHERE email = 'your-email@domain.tld';
SELECT id, "userId", provider, "providerAccountId" FROM "Account" WHERE "userId" IN (
  SELECT id FROM "User" WHERE email = 'your-email@domain.tld'
);
```

### 3. Choose one fix path

Recommended, no-data-loss path:

1. Copy the Keycloak user UUID (`sub`) from Keycloak admin.
2. Insert an account link row:

```sql
INSERT INTO "Account" ("userId", type, provider, "providerAccountId")
SELECT id, 'oauth', 'keycloak', 'KEYCLOAK_USER_UUID'
FROM "User"
WHERE email = 'your-email@domain.tld'
ON CONFLICT DO NOTHING;
```

Fast reset path (destructive, use only if acceptable):

```sql
DELETE FROM "Account"
WHERE "userId" IN (SELECT id FROM "User" WHERE email = 'your-email@domain.tld');

DELETE FROM "Session"
WHERE "userId" IN (SELECT id FROM "User" WHERE email = 'your-email@domain.tld');

DELETE FROM "User"
WHERE email = 'your-email@domain.tld';
```

Then log in again so Linkwarden recreates the account from Keycloak.

## Configuration anchors in this repository

- Keycloak provider wiring is in `linkwarden.nix`.
- Client ID is `linkwarden`.
- Issuer is `https://kc.mrbl.dedyn.io/realms/home`.
