# Monitoring Setup (Prometheus, Loki, Grafana)

Diataxis type: How-to guide

Use this guide to deploy a 7-day retention monitoring stack with a central VM and per-host agents.

## Goal

Deploy:

- Central VM: Prometheus, Loki, Grafana
- Each host: Promtail, Node Exporter

Retention target:

- Metrics: 7 days
- Logs: 7 days

## 1. Configure the central VM

Add to central VM `configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  services.prometheus = {
    enable = true;
    retentionTime = "7d";
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          # Add all your hosts here
          { targets = [ "host1:9100" "host2:9100" "host3:9100" ]; }
        ];
      }
    ];
  };

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server.http_listen_port = 3100;
      ingester = {
        wal = {
          enabled = true;
          dir = "/var/lib/loki/wal";
        };
      };
      storage_config = {
        boltdb_shipper = {
          active_index_directory = "/var/lib/loki/index";
          cache_location = "/var/lib/loki/cache";
          shared_store = "filesystem";
        };
        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };
      schema_config = {
        configs = [{
          from = "2020-10-24";
          store = "boltdb-shipper";
          object_store = "filesystem";
          schema = "v11";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }];
      };
      limits_config = {
        retention_period = "168h"; # 7 days
      };
    };
  };

  services.grafana = {
    enable = true;
    settings.server = {
      http_port = 3000;
      domain = "your-grafana-domain";
      root_url = "http://your-grafana-domain:3000";
    };
    provision = {
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:9090";
        }
        {
          name = "Loki";
          type = "loki";
          url = "http://localhost:3100";
        }
      ];
    };
  };

  # Open necessary ports
  networking.firewall.allowedTCPPorts = [ 3000 3100 9090 ];
}
```

## 2. Configure each host

Add to each host `configuration.nix`:

```nix
{ config, pkgs, ... }:

{
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
        { url = "http://central-vm-ip:3100/loki/api/v1/push"; }
      ];
      scrape_configs = [
        {
          job_name = "system";
          static_configs = [
            {
              targets = [ "localhost" ];
              labels = {
                job = "varlogs";
                __path__ = "/var/log/*log";
              };
            }
          ];
        }
      ];
    };
  };

  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
  };

  networking.firewall.allowedTCPPorts = [ 9100 9080 ];
}
```

- Replace `central-vm-ip` with your central VM’s IP address.
- Add all your hosts’ IPs to the Prometheus `targets` list on the central VM.

## Capacity reference for 7-day retention

### Prometheus

- Typical estimate: 150-300 MB per 1,000 time series per day
- Approximate 7-day total: 1-2 GB per 1,000 time series

Example:

- 5,000 time series can require roughly 5-10 GB for 7 days

### Loki

- Typical estimate: around 1 GB per 1,000 logs/sec per day (depends on log size and compression)
- Approximate 7-day total: 7 GB per 1,000 logs/sec

Common ranges:

- 10-100 logs/sec: about 70 MB-700 MB for 7 days
- 500 logs/sec: about 3.5 GB for 7 days

### Notes

- CPU and RAM profile is usually less affected than storage by retention changes.
- Validate real usage after deployment and tune scrape/log settings as needed.
