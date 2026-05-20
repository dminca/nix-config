# Nextcloud throwing `Invalid scopes: openid profile email groups`

> on a fresh reinstall of Keycloak, if it was already configured on Nextcloud etc.; this error will be thrown after restoring Keycloak from backup

```json
{
  "reqId": "xC35NekT7XCLJDWSmWNo",
  "level": 2,
  "time": "2026-05-20T05:20:36+00:00",
  "remoteAddr": "192.168.178.104",
  "user": "--",
  "app": "user_oidc",
  "method": "GET",
  "url": "/apps/user_oidc/code?error=invalid_scope&error_description=Invalid+scopes%3A+openid+profile+email+groups&state=OG1RTVIKEK28FCDZXKO45K5SGEI5TOOY&iss=https%3A%2F%2Fkc.mrbl.dedyn.io%2Frealms%2Fhome",
  "scriptName": "/index.php",
  "message": "Code login error",
  "userAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.5 Safari/605.1.15",
  "version": "33.0.2.2",
  "data": {
    "app": "user_oidc",
    "error": "invalid_scope",
    "error_description": "Invalid scopes: openid profile email groups"
  }
}
```

The root cause: `groups` is not a built-in Keycloak scope — it was lost when reinstalled. Nextcloud's `user_oidc` app requests it, but Keycloak has no record of it.

**Fix: Create the `groups` client scope in Keycloak**

1. **Keycloak Admin Console** → select realm (`home`) → **Client Scopes** → **Create client scope**
   - Name: `groups`
   - Type: `Optional` (or `Default`)
   - Protocol: `OpenID Connect`
   - Save

2. Go into the new `groups` scope → **Mappers** tab → **Add mapper** → **By configuration** → **Group Membership**
   - Name: `groups`
   - Token Claim Name: `groups`
   - Full group path: OFF (just group names, not `/admins`)
   - Add to ID token: ON
   - Add to access token: ON
   - Add to userinfo: ON
   - Save

3. **Clients** → your Nextcloud client → **Client Scopes** tab → **Add client scope** → add `groups` as **Optional** (or Default)

4. Do the same for the Linkwarden client if it also requests groups (though from your config it doesn't seem to — it only uses `openid profile email`).

**Why this happened:** Keycloak ships with `openid`, `profile`, `email`, `roles`, etc. as built-in scopes, but `groups` is a custom scope you had previously created manually. A fresh install wipes all realm customizations unless you restore from a realm export JSON.

**To avoid this in future reinstalls**, export a full realm backup from **Realm Settings** → **Action** → **Partial export** (include clients and roles) and commit to nix-config. Can then import it on fresh installs.

**Pro tip**: this is how to check available scopes:
1. Realm settings
1. General tab (scroll to bottom)
1. Endpoints
1. (click) OpenID Endpoint Configuration
