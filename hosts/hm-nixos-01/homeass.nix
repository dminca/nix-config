{
  ...
}:
{
  services.home-assistant = {
    enable = true;
    openFirewall = true;
    configDir = "/mnt/appdata/home-assistant";
    extraComponents = [
      "hue"
      "met"
      "zeroconf"
      "apple_tv"
      "homekit"
      "homekit_controller"
      "matter"
      "thread"
      "bluetooth"
      "hisense_aehw4a1"
      "ecovacs"
      "adguard"
    ];

    # Keep a minimal baseline in Nix; integrations/devices are added in the UI.
    config = {
      default_config = { };
      homeassistant = {
        name = "hm-nixos-01";
        time_zone = "UTC";
        external_url = "https://ha.mrbl.dedyn.io";
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
