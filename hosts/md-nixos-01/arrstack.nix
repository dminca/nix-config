{
  ...
}:
{
	users.groups.media = { };

	users.users.radarr.extraGroups = [ "media" ];
	users.users.sonarr.extraGroups = [ "media" ];
	users.users.bazarr.extraGroups = [ "media" ];
	users.users.jellyfin.extraGroups = [ "media" ];

	services.radarr = {
		enable = true;
		openFirewall = true;
		dataDir = "/mnt/arr-data/appdata/radarr";
	};

	services.sonarr = {
		enable = true;
		openFirewall = true;
		dataDir = "/mnt/arr-data/appdata/sonarr";
	};

	services.bazarr = {
		enable = true;
		openFirewall = true;
		dataDir = "/mnt/arr-data/appdata/bazarr";
	};

	services.jellyfin = {
		enable = true;
		openFirewall = true;
		dataDir = "/mnt/arr-data/appdata/jellyfin";
	};

	systemd.tmpfiles.rules = [
		"d /mnt/arr-data/appdata 0755 root root -"
		"d /mnt/arr-data/appdata/radarr 0750 radarr media -"
		"d /mnt/arr-data/appdata/sonarr 0750 sonarr media -"
		"d /mnt/arr-data/appdata/bazarr 0750 bazarr media -"
		"d /mnt/arr-data/appdata/jellyfin 0750 jellyfin media -"
		"d /mnt/arr-data/media 2775 root media -"
		"d /mnt/arr-data/media/movies 2775 root media -"
		"d /mnt/arr-data/media/tv 2775 root media -"
		"d /mnt/arr-data/media/downloads 2775 root media -"
	];
}

