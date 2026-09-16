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
      "mon-nixos-01.home.arpa:9100" # mon-nixos-01
      "nc-nixos-01.home.arpa:9100" # nc-nixos-01
      "ic-nixos-01.home.arpa:9100" # ic-nixos-01
      "lw-nixos-01.home.arpa:9100" # lw-nixos-01
      "rp-nixos-01.home.arpa:9100" # rp-nixos-01
      "kc-nixos-01.home.arpa:9100" # kc-nixos-01
      "hs-nixos-01.home.arpa:9100" # hs-nixos-01
      "notes-nixos-01.home.arpa:9100" # notes-nixos-01
      "rss-nixos-01.home.arpa:9100" # rss-nixos-01
    ];
    dashboardFiles = [
      ../../modules/monitoring/grafana-dashboards/node-overview.json
      ../../modules/monitoring/grafana-dashboards/hardware-metrics.json
    ];
  };
}
