# Keycloak + Nextcloud Passwordless (Passkeys)

This runbook configures a dedicated Keycloak realm for Nextcloud and enables WebAuthn Passwordless for manually created users.

## Topology assumptions

- Public URLs:
  - https://kc.mrbl.dedyn.io
  - https://nc.mrbl.dedyn.io
- Caddy is the public reverse proxy.
- Keycloak upstream is reachable from Caddy on http://<IP_OF_KC_NIXOS_01>:8080.
- Nextcloud upstream is reachable from Caddy on http://<IP_OF_NC_NIXOS_01>:80.

## 1) Separate realm

Create a dedicated realm for user auth (do not use master for application sign-in):

- Realm name: home
- Realm enabled: yes

## 2) Create users in Keycloak

Create users manually:

- Bob
- Alice
- Carol

For each user:

1. Set email.
2. Set temporary password.
3. Add required action CONFIGURE_RECOVERY_AUTHN_CODES (optional but recommended).
4. Add required action WEBAUTHN_REGISTER_PASSWORDLESS.

## 3) Create groups (recommended model)

Use business groups and one technical access group:

- family
- others
- nextcloud-users

Membership example:

- Bob -> family + nextcloud-users
- Alice -> family + nextcloud-users
- Carol -> others (add nextcloud-users only when you want to grant Nextcloud access)

Why this model:

- family and others represent household structure.
- nextcloud-users is only for application authorization.
- You can move people between family/others without changing app login policy.

## 4) Configure passwordless WebAuthn policy

In realm home:

1. Go to Realm settings -> Authentication -> Required actions and ensure Webauthn Register Passwordless is enabled.
2. Go to Authentication -> Policies -> WebAuthn Passwordless Policy and set:
   - Relying Party Entity Name: mrbl
   - Relying Party ID: kc.mrbl.dedyn.io
   - User Verification Requirement: required
   - Require Resident Key: Yes
   - Attestation Conveyance Preference: not specified

## 5) Create Keycloak client for Nextcloud

In realm home, create client:

- Client type: OpenID Connect
- Client ID: nextcloud
- Client authentication: On (confidential client)
- Standard flow: On
- Direct access grants: Off

Set URLs:

- Root URL: https://nc.mrbl.dedyn.io
- Home URL: https://nc.mrbl.dedyn.io
- Valid redirect URIs: https://nc.mrbl.dedyn.io/apps/user_oidc/code
- Valid redirect URIs (recommended additional entry): https://nc.mrbl.dedyn.io/*
- Valid post logout redirect URIs: https://nc.mrbl.dedyn.io/*
- Web origins: https://nc.mrbl.dedyn.io

Save and copy the generated client secret.

## 6) Configure claim mappers in Keycloak

Client scope mappers should include at least:

- preferred_username
- email
- name
- groups (required if you want Nextcloud access restriction by group)

For groups mapper, include full group path so policies stay unambiguous (for example /nextcloud-users).

If using group-based access in Nextcloud, allow only nextcloud-users.

## 7) Enable OIDC app in Nextcloud

Run on Nextcloud host:

```bash
sudo -u nextcloud php /var/lib/nextcloud/occ app:enable user_oidc
```

Configure user_oidc app in Nextcloud admin UI with:

- Discovery URL:
  https://kc.mrbl.dedyn.io/realms/home/.well-known/openid-configuration
- Identifier: keycloak-home (any stable label is fine)
- Client ID: nextcloud
- Client secret: <from keycloak client>
- Scopes: openid profile email groups
- Unique user ID mapping: preferred_username

Optional access restriction:

- Use group provisioning: On
- Restrict login for users that are not in any whitelisted group: On
- Send ID token hint on logout: On
- Check bearer token on API and WebDAV requests: Off (unless you explicitly use bearer tokens for API/WebDAV clients)
- Custom end session endpoint: leave empty when discovery works. Only set it manually if discovery metadata is wrong or unavailable.
- If manual endpoint override is required for Keycloak, use:
  https://kc.mrbl.dedyn.io/realms/home/protocol/openid-connect/logout
- Whitelisted group must be a PHP regex with delimiters. Working example:
  /^\/?(nextcloud-users|family)$/

Notes for Whitelisted group:

- This field is interpreted by preg_match, not as a plain string.
- Patterns like /nextcloud-users or ^(?:group)$ without delimiters can trigger errors such as Unknown modifier 'e' or Unknown modifier '?'.
- If you disable Full group path in Keycloak groups mapper, use:
  /^(nextcloud-users|family)$/

## 8) Reverse proxy and trusted proxy checks

- Caddy must forward:
  - Host
  - X-Forwarded-For
  - X-Forwarded-Host
  - X-Forwarded-Proto
  - X-Forwarded-Port
- Nextcloud trusted_proxies must contain the real IP of rp-nixos-01.
- If discovery validation fails with local IP SSRF protection errors, set this Nextcloud setting:
  allow_local_remote_servers = true
  (NixOS option key in services.nextcloud.settings is snake_case.)

## 9) Enrollment and validation

1. Login once as each user with temporary password.
2. Register at least one passkey when prompted.
3. Logout and login again to confirm passkey sign-in works.
4. Register a second passkey per user for recovery.
5. Verify authorization behavior:
  - Bob and Alice can sign in to Nextcloud.
  - Carol cannot sign in unless she is added to nextcloud-users.

## 10) Optional hardening after validation

- Keep password fallback during rollout.
- After both users are enrolled and tested, tighten flows to prefer passkey-first.
- Keep OTP/recovery codes available for account recovery.

## 11) Passkey-first login flow in Keycloak (working structure)

Keycloak does not allow editing built-in flows directly and Username Password Form is fixed as Required.
Use a copied browser flow with branching subflows.

1. Go to Authentication -> Flows.
2. Copy built-in browser flow and name it browser-passwordless.
3. Inside browser-passwordless, add a parent subflow:
  - Name: Passkey or Password
  - Flow type: Generic
  - Requirement: Alternative
4. Inside Passkey or Password, add subflow A:
  - Name: Passkey branch
  - Flow type: Generic
  - Requirement: Alternative
5. Inside Passkey branch, add executions:
  - Conditional - User Configured (Required)
  - WebAuthn Passwordless Authenticator (Required)
6. Inside Passkey or Password, add subflow B:
  - Name: Password branch
  - Flow type: Form
  - Requirement: Alternative
7. Inside Password branch, add execution:
  - Username Password Form (Required; this is expected and cannot be changed)
8. Bind the new flow in Authentication -> Bindings:
  - Browser Flow: browser-passwordless

Result:

- Users with registered passkeys are prompted for passkey first.
- Users without passkeys can still login with password.

## 12) Troubleshooting logout (Invalid redirect uri)

If Keycloak shows Invalid redirect uri during logout:

1. Re-check nextcloud client login settings in Keycloak include:
  - Valid redirect URIs: https://nc.mrbl.dedyn.io/*
  - Valid post logout redirect URIs: https://nc.mrbl.dedyn.io/*
2. Keep Send ID token hint on logout enabled in Nextcloud user_oidc.
3. If needed, inspect the exact post_logout_redirect_uri in the browser URL and add a matching allowlist entry in Keycloak.
