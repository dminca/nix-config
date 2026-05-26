{
  config,
  lib,
  ...
}:
let
  cfg = config.homelab.monitoring.server;
  prometheusStateDir = "/var/lib/prometheus2";
  prometheusVolume = "/mnt/prometheus-data";
  lokiDataDir = "/mnt/loki-data";
  grafanaDataDir = "/mnt/grafana-data";
  dashboardEtcEntries = lib.listToAttrs (
    map (
      dashboardFile:
      let
        fileName = builtins.baseNameOf dashboardFile;
      in
      {
        name = "grafana-dashboards/${fileName}";
        value.source = dashboardFile;
      }
    ) cfg.dashboardFiles
  );
in
{
  options.homelab.monitoring.server = {
    enable = lib.mkEnableOption "Prometheus + Loki + Grafana monitoring server";

    scrapeTargets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "rp-nixos-01:9100"
        "hm-nixos-01:9100"
      ];
      description = "Static node_exporter targets scraped by Prometheus.";
    };

    dashboardFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ./grafana-dashboards/node-overview.json ];
      description = "Dashboard JSON files provisioned into Grafana.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Prometheus stateDir must remain under /var/lib, so bind the dedicated disk there.
    fileSystems.${prometheusStateDir} = {
      device = prometheusVolume;
      fsType = "none";
      options = [ "bind" ];
    };

    systemd.tmpfiles.rules = [
      "d ${prometheusVolume} 0750 prometheus prometheus - -"
      "z ${prometheusVolume} 0750 prometheus prometheus - -"
      "d ${lokiDataDir} 0750 loki loki - -"
      "z ${lokiDataDir} 0750 loki loki - -"
      "d ${lokiDataDir}/wal 0750 loki loki - -"
      "z ${lokiDataDir}/wal 0750 loki loki - -"
      "d ${lokiDataDir}/index 0750 loki loki - -"
      "z ${lokiDataDir}/index 0750 loki loki - -"
      "d ${lokiDataDir}/cache 0750 loki loki - -"
      "z ${lokiDataDir}/cache 0750 loki loki - -"
      "d ${lokiDataDir}/chunks 0750 loki loki - -"
      "z ${lokiDataDir}/chunks 0750 loki loki - -"
      "d ${grafanaDataDir} 0750 grafana grafana - -"
      "z ${grafanaDataDir} 0750 grafana grafana - -"
    ];

    systemd.services.prometheus.serviceConfig.RequiresMountsFor = [
      prometheusStateDir
      prometheusVolume
    ];

    systemd.services.loki.serviceConfig.RequiresMountsFor = [
      lokiDataDir
    ];

    systemd.services.grafana.serviceConfig.RequiresMountsFor = [
      grafanaDataDir
    ];

    services.prometheus = {
      enable = true;
      listenAddress = "0.0.0.0";
      port = 9090;
      retentionTime = "7d";

      globalConfig = {
        scrape_interval = "30s";
      };

      scrapeConfigs = [
        {
          job_name = "nixos-node-exporter";
          static_configs = [
            {
              targets = cfg.scrapeTargets;
              labels = {
                cluster = config.homelab.monitoring.cluster;
              };
            }
          ];
        }
      ];
    };

    services.loki = {
      enable = true;
      dataDir = lokiDataDir;
      configuration = {
        auth_enabled = false;

        server = {
          http_listen_address = "0.0.0.0";
          http_listen_port = 3100;
        };

        ingester = {
          wal = {
            enabled = true;
            dir = "${lokiDataDir}/wal";
          };
        };

        storage_config = {
          boltdb_shipper = {
            active_index_directory = "${lokiDataDir}/index";
            cache_location = "${lokiDataDir}/cache";
            shared_store = "filesystem";
          };

          filesystem = {
            directory = "${lokiDataDir}/chunks";
          };
        };

        schema_config = {
          configs = [
            {
              from = "2020-10-24";
              store = "boltdb-shipper";
              object_store = "filesystem";
              schema = "v11";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };

        limits_config = {
          retention_period = "168h";
        };
      };
    };

    services.grafana = {
      enable = true;
      dataDir = grafanaDataDir;
      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = 3000;
          domain = "mon.mrbl.dedyn.io";
          root_url = "http://mon.mrbl.dedyn.io:3000";
        };
      };

      provision = {
        enable = true;

        datasources.settings = {
          apiVersion = 1;
          datasources = [
            {
              name = "Prometheus";
              uid = "prometheus";
              type = "prometheus";
              access = "proxy";
              isDefault = true;
              url = "http://127.0.0.1:9090";
            }
            {
              name = "Loki";
              uid = "loki";
              type = "loki";
              access = "proxy";
              url = "http://127.0.0.1:3100";
            }
          ];
        };

        dashboards.settings = {
          apiVersion = 1;
          providers = [
            {
              name = "homelab";
              orgId = 1;
              folder = "Homelab";
              type = "file";
              disableDeletion = false;
              updateIntervalSeconds = 30;
              allowUiUpdates = true;
              options = {
                path = "/etc/grafana-dashboards";
              };
            }
          ];
        };
      };
    };

    environment.etc = dashboardEtcEntries;

    networking.firewall.allowedTCPPorts = [
      3000
      9090
      3100
    ];
  };
}
