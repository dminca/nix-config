{
  ...
}:
{
  services.home-assistant = {
    enable = true;
    openFirewall = true;
    configDir = "/mnt/appdata/home-assistant";

    # Keep a minimal baseline in Nix; integrations/devices are added in the UI.
    config = {
      default_config = { };
      homeassistant = {
        name = "hm-nixos-01";
        time_zone = "UTC";
      };
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [ "10.10.10.135" ];
      };
    };
  };

  # Ensure the persistent appdata directory exists with service ownership.
  systemd.tmpfiles.rules = [
    "d /mnt/appdata/home-assistant 0750 hass hass -"
  ];
}
