{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.home-assistant = {
    enable = true;
    openFirewall = true;
    configDir = "/mnt/appdata/home-assistant";
    extraComponents = [
      "mqtt"
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
      "zha"
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

  # Local MQTT broker for Home Assistant and Zigbee2MQTT.
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        address = "127.0.0.1";
        port = 1883;
        users = {
          zigbee2mqtt = {
            acl = [ "readwrite #" ];
            passwordFile = config.sops.secrets.z2m-mqtt-password.path;
          };
        };
      }
    ];
  };

  # Create a stable device path for the Sonoff Zigbee USB dongle.
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zigbee-sonoff", GROUP="dialout", MODE="0660"
  '';

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      homeassistant.enabled = true;
      permit_join = true;
      mqtt = {
        server = "mqtt://127.0.0.1:1883";
        user = "zigbee2mqtt";
        password = "SOPS_RUNTIME_INJECTED";
      };
      serial = {
        port = "/dev/ttyUSB0";
        adapter = "zstack";
      };
      frontend = {
        enabled = true;
        port = 8099;
      };
    };
  };

  # Allow Zigbee2MQTT service user to access serial adapters.
  users.users.zigbee2mqtt.extraGroups = [ "dialout" ];

  sops.secrets.z2m-mqtt-password = {
    sopsFile = ./secrets/mqtt.yaml;
    key = "z2m_mqtt_password";
    owner = "zigbee2mqtt";
    group = "zigbee2mqtt";
    mode = "0440";
  };

  systemd.services.zigbee2mqtt.preStart = lib.mkAfter ''
    export Z2M_MQTT_PASSWORD="$(tr -d '\n' < ${config.sops.secrets.z2m-mqtt-password.path})"
    ${pkgs.yq-go}/bin/yq eval -i '.mqtt.password = env(Z2M_MQTT_PASSWORD)' ${config.services.zigbee2mqtt.dataDir}/configuration.yaml
  '';

  # Ensure the persistent appdata directory exists with service ownership.
  systemd.tmpfiles.rules = [
    "d /mnt/appdata/home-assistant 0750 hass hass -"
  ];
}
