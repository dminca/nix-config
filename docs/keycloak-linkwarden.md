# Common issues with Keycloak and Linkwarden

> After a fresh re-install of Keycloak and restoration of whatever could be restored,
OIDC will fail; these are some common pitfalls and resolution steps

## `error=OAuthAccountNotLinked`

- simplest approach is to have an already logged-in session and delete account;
in order to allow Keycloak to recreate it
- if that's not possible, the hardest approach follows

That new error means Keycloak auth is now succeeding, but Linkwarden/NextAuth is refusing to attach it to an existing user identity.

`OAuthAccountNotLinked` means Keycloak auth now works, but Linkwarden found an existing account with the same email that is not linked to provider `keycloak`.

OAuth client issue is fixed; now it is an account-linking issue.

Do this on Linkwarden DB host (lw-nixos-01) with a backup first.

1. Backup DB
```bash
sudo -u postgres pg_dump linkwarden > /tmp/linkwarden-before-account-link.sql
```

2. Inspect auth tables and the target user
```bash
sudo -u postgres psql linkwarden
```
Inside psql:
```sql
\dt
SELECT id, email FROM "User" WHERE email = 'your-email@domain.tld';
SELECT id, "userId", provider, "providerAccountId" FROM "Account" WHERE "userId" IN (
  SELECT id FROM "User" WHERE email = 'your-email@domain.tld'
);
```

3. Choose one fix path

1. Safe/no data loss (recommended): link Keycloak to existing user
- In Keycloak admin, open the user and copy the user UUID (this is the OIDC `sub`).
- Insert link row (replace values):
```sql
INSERT INTO "Account" ("userId", type, provider, "providerAccountId")
SELECT id, 'oauth', 'keycloak', 'KEYCLOAK_USER_UUID'
FROM "User"
WHERE email = 'your-email@domain.tld'
ON CONFLICT DO NOTHING;
```
Then retry login.

2. Fast reset (only if acceptable): remove old user identity and recreate via Keycloak
- This can orphan or remove ownership data depending on FK settings, so only do it if you’re okay with that.
```sql
DELETE FROM "Account"
WHERE "userId" IN (SELECT id FROM "User" WHERE email = 'your-email@domain.tld');

DELETE FROM "Session"
WHERE "userId" IN (SELECT id FROM "User" WHERE email = 'your-email@domain.tld');

DELETE FROM "User"
WHERE email = 'your-email@domain.tld';
```
Then log in again with Keycloak to recreate the user.

Notes tied to your repo config:
- Keycloak provider wiring is in linkwarden.nix
- Client id is `linkwarden` in linkwarden.nix
- Issuer is `https://kc.mrbl.dedyn.io/realms/home` in linkwarden.nix

## Setting up Keycloak with Linkwarden (Keycloak realm)

**Keycloak Client Template (Realm: home)**  

### General  
1. Client ID: linkwarden  
2. Name: Linkwarden (optional)  
3. Enabled: ON  
4. Protocol: openid-connect  

### Capability config  
1. Client authentication: ON  
2. Authorization: OFF (unless you explicitly use it)  
3. Standard flow: ON  
4. Direct access grants: OFF  
5. Implicit flow: OFF  
6. Service accounts roles: OFF (not needed for user login)  

### Login settings  
1. Root URL: https://lw.mrbl.dedyn.io  
2. Home URL: https://lw.mrbl.dedyn.io  
3. Valid redirect URIs: https://lw.mrbl.dedyn.io/api/v1/auth/callback/keycloak  
4. Valid post logout redirect URIs: https://lw.mrbl.dedyn.io/*  
5. Web origins: https://lw.mrbl.dedyn.io  
6. Consent required: OFF  

### Credentials  
1. Client authenticator: Client Id and Secret  
2. Regenerate secret, copy it immediately  
3. Put that exact value into your SOPS key KEYCLOAK_CLIENT_SECRET on Linkwarden host  
4. Rebuild/restart Linkwarden:

```bash
sudo nixos-rebuild switch --flake .#lw-nixos-01
sudo systemctl restart linkwarden.service
```

**Fast Verification (2 minutes)**  
1. Confirm issuer is valid:
```bash
curl -fsSL https://kc.mrbl.dedyn.io/realms/home/.well-known/openid-configuration | jq .issuer,.token_endpoint
```
Expected issuer should be exactly https://kc.mrbl.dedyn.io/realms/home.

2. Confirm Linkwarden still has the same client id and issuer in Nix:
- KEYCLOAK_CLIENT_ID = linkwarden  
- KEYCLOAK_ISSUER = https://kc.mrbl.dedyn.io/realms/home

3. Check fresh logs right after a login attempt:
```bash
sudo journalctl -u linkwarden.service -n 120 -e
```
