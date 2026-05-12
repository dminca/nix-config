{ ... }:
{
  users.groups.media = { };

  users.users.qbittorrent.extraGroups = [ "media" ];
  users.users.prowlarr.extraGroups = [ "media" ];

  services.prowlarr = {
    enable = true;
    openFirewall = true;
    dataDir = "/srv/appdata/prowlarr";
  };

  services.qbittorrent = {
    enable = true;
    openFirewall = true;
    profileDir = "/srv/appdata/qbittorrent";

    # Keep download payload outside profileDir to separate snapshots/backups.
    serverConfig = {
      Preferences = {
        SavePath = "/srv/downloads/complete";
        TempPath = "/srv/downloads/incomplete";
        TempPathEnabled = true;
      };
    };
  };

  # /srv/downloads is intended for your mounted dataset or block device.
  systemd.tmpfiles.rules = [
    "d /srv/appdata 0755 root root -"
    "d /srv/appdata/prowlarr 0750 prowlarr media -"
    "d /srv/appdata/qbittorrent 0750 qbittorrent media -"
    "d /srv/downloads 2775 root media -"
    "d /srv/downloads/incomplete 2775 root media -"
    "d /srv/downloads/complete 2775 root media -"
  ];
}

