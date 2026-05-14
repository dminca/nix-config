# Monitoring setup

## Resources

Set retention for both metrics (Prometheus) and logs (Loki) to 7 days, storage requirements will be significantly reduced compared to longer retention

### Prometheus (Metrics) — 7 Days Retention
- Storage usage is roughly linear with retention.
- Typical estimate: **~150–300 MB per 1,000 time series per day**.
- For 7 days: **1–2 GB per 1,000 time series**.
- Example: If you scrape 50 targets with 100 metrics each (5,000 time series), expect **5–10 GB** for 7 days.

### Loki (Logs) — 7 Days Retention
- Storage depends on log volume and compression.
- Typical estimate: **~1 GB per 1,000 logs/sec per day** (varies by log size).
- For 7 days: **7 GB per 1,000 logs/sec**.
- For small setups (e.g., 10–100 logs/sec): **70 MB–700 MB for 7 days**.
- For moderate setups (e.g., 500 logs/sec): **~3.5 GB for 7 days**.

### Summary Table (7d Retention)

| Component   | Storage per 7d (approx.) |
|-------------|-------------------------|
| Prometheus  | 1–2 GB per 1,000 time series |
| Loki        | 0.1–7 GB (depends on log rate) |

**RAM and CPU requirements remain the same** as before; only storage is affected by retention.

**Tips:**
- Always monitor actual usage after deployment; these are estimates.
- You can further reduce storage by increasing scrape intervals (Prometheus) or log filtering (Loki).
- Both Prometheus and Loki support compaction and retention policies to automatically delete old data.

## Configuration

NixOS configuration snippets for:

- The central VM (Prometheus, Loki, Grafana)
- Each host (Promtail, Node Exporter)

---

### 1. Central VM (Prometheus, Loki, Grafana)

Add to your central VM’s `configuration.nix`:

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

---

### 2. Each Host (Promtail, Node Exporter)

Add to each host’s `configuration.nix`:

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
