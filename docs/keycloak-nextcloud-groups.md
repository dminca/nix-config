# Fix Nextcloud OIDC Error: Invalid Scopes

Diataxis type: How-to guide

Use this guide when Nextcloud login fails with `Invalid scopes: openid profile email groups` after a Keycloak reinstall or partial restore.

## Symptom

Nextcloud `user_oidc` reports an `invalid_scope` error mentioning `groups`.

## Cause

`groups` is typically a custom Keycloak client scope. If the realm was rebuilt without restoring custom scopes, Nextcloud still requests `groups` but Keycloak no longer has it.

## Fix

### 1. Recreate the `groups` client scope

In Keycloak Admin for realm `home`:

1. Open Client Scopes.
2. Create scope:
3. Name: `groups`
4. Type: `Optional` (or `Default`)
5. Protocol: `OpenID Connect`

### 2. Add a Group Membership mapper

Inside the `groups` scope:

1. Mappers -> Add mapper -> Group Membership
2. Name: `groups`
3. Token Claim Name: `groups`
4. Full group path: off (or on if your policy expects full path)
5. Add to ID token: on
6. Add to access token: on
7. Add to userinfo: on

### 3. Attach `groups` to the Nextcloud client

1. Clients -> `nextcloud` -> Client Scopes
2. Add `groups` as Optional (or Default)

If another client requests `groups`, attach it there as well.

## Prevention

- Export and version realm configuration (clients, scopes, roles) before reinstalling Keycloak.
- Restore the exported realm on fresh deployments.

## Verification

1. Retry Nextcloud OIDC login.
2. Confirm the error is gone.
3. Optionally inspect the OIDC discovery document and client scopes in Keycloak endpoints.
