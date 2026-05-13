{
  ...
}:
{
	# Explicit app ports used by the Caddy reverse proxy on rp-nixos-01.
	networking.firewall.allowedTCPPorts = [
		7878 # radarr
		8989 # sonarr
		6767 # bazarr
		8096 # jellyfin
	];

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

  systemd.tmpfiles.rules = [
    "d /mnt/arr-data/appdata 0775 root nogroup -"
    "d /mnt/arr-data/appdata/radarr 0770 radarr nogroup -"
    "d /mnt/arr-data/appdata/sonarr 0770 sonarr nogroup -"
    "d /mnt/arr-data/appdata/bazarr 0770 bazarr nogroup -"
    "d /mnt/arr-data/appdata/jellyfin 0770 jellyfin nogroup -"
    "d /mnt/arr-data/media 2775 root nogroup -"
    "d /mnt/arr-data/media/movies 2775 root nogroup -"
    "d /mnt/arr-data/media/tv 2775 root nogroup -"
    "d /mnt/arr-data/media/downloads 2775 root nogroup -"
    "d /mnt/data-indexers 2775 root nogroup -"
		# NFS export does not support POSIX ACLs here; rely on shared group perms.
		# setgid (2xxx) keeps new content in nogroup so radarr/sonarr can import.
		"d /mnt/data-indexers/appdata/qbittorrent 2775 root nogroup -"
		"d /mnt/data-indexers/appdata/qbittorrent/qBittorrent 2775 root nogroup -"
		"d /mnt/data-indexers/appdata/qbittorrent/qBittorrent/downloads 2775 root nogroup -"
  ];
}

