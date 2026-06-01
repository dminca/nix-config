{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.monitoring.agent;
in
{
  options.homelab.monitoring = {
    cluster = lib.mkOption {
      type = lib.types.str;
      default = "homelab";
      description = "Cluster label attached to metrics and logs.";
    };

    lokiPushUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://10.10.10.187:3100/loki/api/v1/push";
      description = "Loki push URL used by Fluent Bit clients.";
    };

    agent = {
      enable = lib.mkEnableOption "Fluent Bit + node_exporter monitoring agent";

      extraScrapeConfigs = lib.mkOption {
        type = with lib.types; listOf attrs;
        default = [ ];
        description = "Deprecated Promtail scrape configs. Kept for compatibility and currently ignored.";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    let
      lokiUrlMatch = builtins.match "^(https?)://([^/:]+)(:([0-9]+))?(/.*)$" config.homelab.monitoring.lokiPushUrl;
      lokiScheme = if lokiUrlMatch == null then "http" else builtins.elemAt lokiUrlMatch 0;
      lokiHost = if lokiUrlMatch == null then "127.0.0.1" else builtins.elemAt lokiUrlMatch 1;
      lokiPort =
        if lokiUrlMatch == null then
          3100
        else if builtins.elemAt lokiUrlMatch 3 == null then
          (if lokiScheme == "https" then 443 else 80)
        else
          lib.toInt (builtins.elemAt lokiUrlMatch 3);
      lokiUri = if lokiUrlMatch == null then "/loki/api/v1/push" else builtins.elemAt lokiUrlMatch 4;
    in
    {
    services.prometheus.exporters.node = {
      enable = true;
      openFirewall = true;
      port = 9100;
      extraFlags = lib.optionals config.boot.isContainer [
        "--path.udev.data=/var/empty"
        "--no-collector.thermal_zone"
      ];
    };

    services.fluent-bit = {
      enable = true;
      settings = {
        service = {
          flush = 1;
          log_level = "info";
        };

        parsers = [
          {
            name = "caddy_json";
            format = "json";
          }
        ];

        pipeline = {
          inputs = [
            {
              name = "systemd";
              tag = "systemd-journal";
            }
            {
              name = "tail";
              tag = "varlogs";
              path = "/var/log/*.log";
              read_from_head = true;
            }
          ] ++ lib.optionals config.services.caddy.enable [
            {
              name = "systemd";
              tag = "caddy-journal";
              systemd_filter = "_SYSTEMD_UNIT=caddy.service";
            }
          ];

          filters = lib.optionals config.services.caddy.enable [
            {
              name = "grep";
              match = "systemd-journal";
              exclude = "_SYSTEMD_UNIT ^caddy\\.service$";
            }
            {
              name = "parser";
              match = "caddy-journal";
              key_name = "MESSAGE";
              parser = "caddy_json";
              reserve_data = true;
              preserve_key = false;
            }
          ];

          outputs = [
            {
              name = "loki";
              match = "*";
              host = lokiHost;
              port = lokiPort;
              uri = lokiUri;
              tls = lokiScheme == "https";
              labels = "job=fluent-bit,host=${config.networking.hostName},cluster=${config.homelab.monitoring.cluster}";
              line_format = "json";
            }
          ];
        };
      };
    };

    warnings = lib.optional (cfg.extraScrapeConfigs != [ ])
      "homelab.monitoring.agent.extraScrapeConfigs is ignored because Promtail was removed upstream; migrate custom pipelines to services.fluent-bit.settings.";
  }
  );
}

