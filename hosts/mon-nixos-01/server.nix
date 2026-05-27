{
  ...
}:
{
  sops.secrets.keycloak-grafana-secret = {
    sopsFile = ./secrets/keycloak-grafana-secret.yaml;
    key = "client_secret";
    owner = "grafana";
    group = "grafana";
    mode = "0400";
  };

  homelab.monitoring.server = {
    enable = true;
    scrapeTargets = [
      "10.10.10.187:9100" # mon-nixos-01
      "10.10.10.140:9100" # hm-nixos-01
      "10.10.10.156:9100" # nc-nixos-01
      "10.10.10.162:9100" # ic-nixos-01
      "10.10.10.153:9100" # lw-nixos-01
      "10.10.10.135:9100" # rp-nixos-01
      "10.10.10.118:9100" # kc-nixos-01
    ];
    dashboardFiles = [
      ../../modules/monitoring/grafana-dashboards/node-overview.json
      ../../modules/monitoring/grafana-dashboards/hardware-metrics.json
    ];
  };
}
