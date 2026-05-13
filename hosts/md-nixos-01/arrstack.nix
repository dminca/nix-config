{
  ...
}:
let
  vpnInterface = "ens19";
in
{
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

  users.users.radarr.extraGroups = [ "nogroup" ];
  users.users.sonarr.extraGroups = [ "nogroup" ];
  users.users.bazarr.extraGroups = [ "nogroup" ];
  users.users.jellyfin.extraGroups = [ "nogroup" ];

  services.radarr = {
    enable = true;
    openFirewall = false;
    dataDir = "/mnt/arr-data/appdata/radarr";
  };

  services.sonarr = {
    enable = true;
    openFirewall = false;
    dataDir = "/mnt/arr-data/appdata/sonarr";
  };

  services.bazarr = {
    enable = true;
    openFirewall = false;
    dataDir = "/mnt/arr-data/appdata/bazarr";
  };

  services.jellyfin = {
    enable = true;
    openFirewall = false;
    dataDir = "/mnt/arr-data/appdata/jellyfin";
  };

  services.qbittorrent = {
    enable = true;
    openFirewall = false;
    profileDir = "/mnt/arr-data/appdata/qbittorrent";

    # Keep download payload outside profileDir to separate snapshots/backups.
    serverConfig = {
      Preferences = {
        "Connection\\Interface" = vpnInterface;
        "Connection\\InterfaceAddress" = "";
        SavePath = "/mnt/arr-data/downloads/complete";
        TempPath = "/mnt/arr-data/downloads/incomplete";
        TempPathEnabled = true;
        "WebUI\\Address" = "*";
        "WebUI\\Port" = 8080;
        "WebUI\\ReverseProxySupportEnabled" = true;
      };
    };
  };

  # qBittorrent kill-switch: block qbittorrent user egress outside VPN iface.
  # This prevents leaks if routing changes or the tunnel goes down.
  networking.firewall.extraCommands = ''
    iptables -I OUTPUT 1 -m owner --uid-owner qbittorrent -o lo -j ACCEPT
    iptables -I OUTPUT 2 -m owner --uid-owner qbittorrent -o ${vpnInterface} -j ACCEPT
    iptables -I OUTPUT 3 -m owner --uid-owner qbittorrent -j REJECT
    ip6tables -I OUTPUT 1 -m owner --uid-owner qbittorrent -o lo -j ACCEPT
    ip6tables -I OUTPUT 2 -m owner --uid-owner qbittorrent -o ${vpnInterface} -j ACCEPT
    ip6tables -I OUTPUT 3 -m owner --uid-owner qbittorrent -j REJECT
  '';

  networking.firewall.extraStopCommands = ''
    iptables -D OUTPUT -m owner --uid-owner qbittorrent -o lo -j ACCEPT || true
    iptables -D OUTPUT -m owner --uid-owner qbittorrent -o ${vpnInterface} -j ACCEPT || true
    iptables -D OUTPUT -m owner --uid-owner qbittorrent -j REJECT || true
    ip6tables -D OUTPUT -m owner --uid-owner qbittorrent -o lo -j ACCEPT || true
    ip6tables -D OUTPUT -m owner --uid-owner qbittorrent -o ${vpnInterface} -j ACCEPT || true
    ip6tables -D OUTPUT -m owner --uid-owner qbittorrent -j REJECT || true
  '';

  # /mnt/arr-data/downloads is intended for your mounted dataset or block device.
  systemd.tmpfiles.rules = [
    "d /mnt/arr-data/appdata 0755 root root -"
    "d /mnt/arr-data/appdata/radarr 0750 radarr nogroup -"
    "d /mnt/arr-data/appdata/sonarr 0750 sonarr nogroup -"
    "d /mnt/arr-data/appdata/bazarr 0750 bazarr nogroup -"
    "d /mnt/arr-data/appdata/jellyfin 0750 jellyfin nogroup -"
    "d /mnt/arr-data/appdata/prowlarr 0750 prowlarr nogroup -"
    "d /mnt/arr-data/appdata/qbittorrent 0750 qbittorrent nogroup -"
    "d /mnt/arr-data/media 2775 root nogroup -"
    "d /mnt/arr-data/media/movies 2775 root nogroup -"
    "d /mnt/arr-data/media/tv 2775 root nogroup -"
    "d /mnt/arr-data/media/downloads 2775 root nogroup -"
    "d /mnt/arr-data/downloads 2775 root nogroup -"
    "d /mnt/arr-data/downloads/incomplete 2775 root nogroup -"
    "d /mnt/arr-data/downloads/complete 2775 root nogroup -"
  ];
}
