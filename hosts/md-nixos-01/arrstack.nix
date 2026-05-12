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
		dataDir = "/srv/appdata/radarr";
	};

	services.sonarr = {
		enable = true;
		openFirewall = true;
		dataDir = "/srv/appdata/sonarr";
	};

	services.bazarr = {
		enable = true;
		openFirewall = true;
		dataDir = "/srv/appdata/bazarr";
	};

	services.jellyfin = {
		enable = true;
		openFirewall = true;
		dataDir = "/srv/appdata/jellyfin";
	};

	# /srv/media is intended for your mounted dataset or block device.
	systemd.tmpfiles.rules = [
		"d /srv/appdata 0755 root root -"
		"d /srv/appdata/radarr 0750 radarr media -"
		"d /srv/appdata/sonarr 0750 sonarr media -"
		"d /srv/appdata/bazarr 0750 bazarr media -"
		"d /srv/appdata/jellyfin 0750 jellyfin media -"
		"d /srv/media 2775 root media -"
		"d /srv/media/movies 2775 root media -"
		"d /srv/media/tv 2775 root media -"
		"d /srv/media/downloads 2775 root media -"
	];
}

