# Nextcloud: group management & quotas

> Create groups in Nextcloud and set quotas on them

The run-once provisioning service is now in nextcloud.nix. It will:

1. Wait for Nextcloud initialization (after nextcloud-setup.service)
2. Run on boot target
3. Skip automatically once /var/lib/nextcloud/.provisioned-family exists
4. Create the groups adults, kids, guests
5. Write the stamp file so it does not run again on future boots

How to apply:
1. sudo nixos-rebuild switch --flake .
2. Optional immediate run now: sudo systemctl start nextcloud-provision-family.service
3. Check result: sudo systemctl status nextcloud-provision-family.service

If you ever want to rerun it:
1. sudo rm /var/lib/nextcloud/.provisioned-family
2. sudo systemctl start nextcloud-provision-family.service

---

Key point first: Nextcloud has user quotas, not true group quotas. In practice you define groups, then set per-user quotas for members of each group.

1. One-time/manual commands (good for testing)

```bash
# Create groups
sudo nextcloud-occ group:add adults
sudo nextcloud-occ group:add kids
sudo nextcloud-occ group:add guests

# Add users to groups
sudo nextcloud-occ group:adduser adults alice
sudo nextcloud-occ group:adduser adults bob
sudo nextcloud-occ group:adduser kids charlie
sudo nextcloud-occ group:adduser guests grandma

# Set per-user quotas
sudo nextcloud-occ user:setting alice files quota "200 GB"
sudo nextcloud-occ user:setting bob files quota "200 GB"
sudo nextcloud-occ user:setting charlie files quota "50 GB"
sudo nextcloud-occ user:setting grandma files quota "20 GB"
```

2. NixOS-managed (recommended, repeatable)
Add a provisioning service in your Nextcloud host config that runs after Nextcloud setup:

```nix
{
  systemd.services.nextcloud-provision-users = {
    description = "Provision Nextcloud groups, memberships, and quotas";
    after = [ "nextcloud-setup.service" ];
    wants = [ "nextcloud-setup.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";

    script = ''
      set -euo pipefail

      # Groups (idempotent)
      nextcloud-occ group:add adults || true
      nextcloud-occ group:add kids || true
      nextcloud-occ group:add guests || true

      # Memberships (idempotent)
      nextcloud-occ group:adduser adults alice || true
      nextcloud-occ group:adduser adults bob || true
      nextcloud-occ group:adduser kids charlie || true
      nextcloud-occ group:adduser guests grandma || true

      # Quotas (safe to re-run)
      nextcloud-occ user:setting alice files quota "200 GB"
      nextcloud-occ user:setting bob files quota "200 GB"
      nextcloud-occ user:setting charlie files quota "50 GB"
      nextcloud-occ user:setting grandma files quota "20 GB"
    '';
  };
}
```

3. Apply

```bash
sudo nixos-rebuild switch --flake .
sudo systemctl start nextcloud-provision-users.service
```

4. Verify

```bash
sudo nextcloud-occ group:list
sudo nextcloud-occ user:info alice
```

Recommended policy pattern
1. Adults: larger quota (for example 150-300 GB)
2. Kids: smaller quota (for example 20-80 GB)
3. Guests: very small quota (for example 5-20 GB)

