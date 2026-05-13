{
  pkgs,
  config,
  lib,
  ...
}:
{
  # ── Collabora Online (CODE) server ────────────────────────────────────────
  services.collabora-online = {
    enable = true;
    settings = {
      ssl.enable = false;
      ssl.termination = true;
      server_name = "office.mrbl.dedyn.io";
    };
    # The NixOS settings attrset cannot express XML attributes (allow="true")
    # on text nodes, so we patch the generated coolwsd.xml via a systemd
    # override that runs xmlstarlet before coolwsd starts.
  };

  # Patch the allow="true" attribute onto the wopi host entry after coolwsd
  # writes its config. xmlstarlet is idempotent here.
  systemd.services.collabora-online = {
    path = [ pkgs.xmlstarlet ];
    preStart = lib.mkAfter ''
      cfg=/etc/coolwsd/coolwsd.xml

      # Switch alias_groups to "groups" mode (required for custom hosts)
      xmlstarlet ed -L \
        -u '//storage/wopi/alias_groups/@mode' -v 'groups' \
        "$cfg"

      # Remove any group we added in a previous run (idempotency)
      xmlstarlet ed -L \
        -d '//storage/wopi/alias_groups/group[host[text()="https://nc\.mrbl\.dedyn\.io"]]' \
        "$cfg" || true

      # Add the Nextcloud group
      xmlstarlet ed -L \
        -s '//storage/wopi/alias_groups' -t elem -n group -v "" \
        "$cfg"
      xmlstarlet ed -L \
        -s '//storage/wopi/alias_groups/group[not(host)]' -t elem -n host \
          -v 'https://nc\.mrbl\.dedyn\.io' \
        "$cfg"
      xmlstarlet ed -L \
        -i '//storage/wopi/alias_groups/group/host[not(@allow)]' \
          -t attr -n allow -v 'true' \
        "$cfg"
    '';
  };

  # Allow Caddy (rp-nixos-01) to reach coolwsd directly
  networking.firewall.allowedTCPPorts = [ 9980 ];

  # ── Wire Nextcloud richdocuments app to the CODE server ───────────────────
  # Runs once after nextcloud-setup; idempotent (occ config:app:set is safe to re-run).
  systemd.services.nextcloud-richdocuments-config = {
    description = "Configure Nextcloud richdocuments (Office) app";
    after = [ "nextcloud-setup.service" ];
    requires = [ "nextcloud-setup.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "nextcloud";
      RemainAfterExit = true;
      ExecStart = pkgs.writeScript "configure-richdocuments" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        /run/current-system/sw/bin/nextcloud-occ config:app:set richdocuments wopi_url \
          --value="https://office.mrbl.dedyn.io"
        /run/current-system/sw/bin/nextcloud-occ config:app:set richdocuments public_wopi_url \
          --value="https://office.mrbl.dedyn.io"
        /run/current-system/sw/bin/nextcloud-occ config:app:set richdocuments wopi_allowlist \
          --value="127.0.0.1"
      '';
    };
  };
}
