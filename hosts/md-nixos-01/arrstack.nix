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

	users.groups.media = { };

	users.users.radarr.extraGroups = [ "media" ];
	users.users.sonarr.extraGroups = [ "media" ];
	users.users.bazarr.extraGroups = [ "media" ];
	users.users.jellyfin.extraGroups = [ "media" ];

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

