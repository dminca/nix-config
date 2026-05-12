{
  ...
}:
{
  # Fixed GID must match md-nixos-01 for shared storage permissions.
  users.groups.prowlarr = { };

  users.users.qbittorrent.extraGroups = [ "nogroup" ];
  users.users.prowlarr = {
    isSystemUser = true;
    group = "prowlarr";
    extraGroups = [ "nogroup" ];
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
    "d /mnt/arr-data/appdata/prowlarr 0750 prowlarr nogroup -"
    "d /mnt/arr-data/appdata/qbittorrent 0750 qbittorrent nogroup -"
    "d /mnt/arr-data/downloads 2775 root nogroup -"
    "d /mnt/arr-data/downloads/incomplete 2775 root nogroup -"
    "d /mnt/arr-data/downloads/complete 2775 root nogroup -"
  ];
}

