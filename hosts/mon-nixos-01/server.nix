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
    ];
    dashboardFiles = [
      ../../modules/monitoring/grafana-dashboards/node-overview.json
    ];
  };
}
