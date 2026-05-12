{ ... }:
{
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
    openFirewall = true;
    dataDir = "/mnt/arr-data/appdata/prowlarr";
  };

  services.qbittorrent = {
    enable = true;
    openFirewall = true;
    profileDir = "/mnt/arr-data/appdata/qbittorrent";

    # Keep download payload outside profileDir to separate snapshots/backups.
    serverConfig = {
      Preferences = {
        SavePath = "/mnt/arr-data/downloads/complete";
        TempPath = "/mnt/arr-data/downloads/incomplete";
        TempPathEnabled = true;
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

