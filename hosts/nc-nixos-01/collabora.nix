{ pkgs, config, ... }:
{
  # ── Collabora Online (CODE) server ────────────────────────────────────────
  services.collabora-online = {
    enable = true;
    settings = {
      ssl.enable = false;
      ssl.termination = true;
      server_name = "office.mrbl.dedyn.io";
    };
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
          --value=""
      '';
    };
  };
}
