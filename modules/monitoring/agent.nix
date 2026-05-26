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
      description = "Loki push URL used by Promtail clients.";
    };

    agent.enable = lib.mkEnableOption "Promtail + node_exporter monitoring agent";
  };

  config = lib.mkIf cfg.enable {
    services.prometheus.exporters.node = {
      enable = true;
      openFirewall = true;
      port = 9100;
    };

    services.promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 9080;
          grpc_listen_port = 0;
        };

        positions = {
          filename = "/var/lib/promtail/positions.yaml";
        };

        clients = [
          {
            url = config.homelab.monitoring.lokiPushUrl;
          }
        ];

        scrape_configs = [
          {
            job_name = "systemd-journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = config.networking.hostName;
                cluster = config.homelab.monitoring.cluster;
              };
            };
          }
          {
            job_name = "varlogs";
            static_configs = [
              {
                targets = [ "localhost" ];
                labels = {
                  job = "varlogs";
                  host = config.networking.hostName;
                  cluster = config.homelab.monitoring.cluster;
                  __path__ = "/var/log/*.log";
                };
              }
            ];
          }
        ];
      };
    };
  };
}
