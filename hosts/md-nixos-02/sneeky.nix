{
  ...
}:
{
  # Explicit app ports used by the Caddy reverse proxy on rp-nixos-01.
  networking.firewall.allowedTCPPorts = [
    9696 # prowlarr
    8080 # qbittorrent Web UI
  ];

  users.groups.prowlarr = { };
  users.groups.media = { };

  users.users.qbittorrent.extraGroups = [ "media" ];
  users.users.prowlarr = {
    isSystemUser = true;
    group = "prowlarr";
    extraGroups = [ "media" ];
  };

  services.prowlarr = {
    enable = true;
    openFirewall = false;
    dataDir = "/mnt/arr-data/appdata/prowlarr";
  };

  services.qbittorrent = {
    enable = true;
    openFirewall = false;
    profileDir = "/mnt/arr-data/appdata/qbittorrent";

    # Keep download payload outside profileDir to separate snapshots/backups.
    serverConfig = {
      Preferences = {
        SavePath = "/mnt/arr-data/downloads/complete";
        TempPath = "/mnt/arr-data/downloads/incomplete";
        TempPathEnabled = true;
        "WebUI\\Address" = "*";
        "WebUI\\Port" = 8080;
        "WebUI\\ReverseProxySupportEnabled" = true;
      };
    };
  };

  # /mnt/arr-data/downloads is intended for your mounted dataset or block device.
  systemd.tmpfiles.rules = [
    "d /mnt/arr-data/appdata 0755 root root -"
    "d /mnt/arr-data/appdata/prowlarr 0750 prowlarr media -"
    "d /mnt/arr-data/appdata/qbittorrent 0750 qbittorrent media -"
    "d /mnt/arr-data/downloads 2775 root media -"
    "d /mnt/arr-data/downloads/incomplete 2775 root media -"
    "d /mnt/arr-data/downloads/complete 2775 root media -"
  ];
}

