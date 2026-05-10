{
  config,
  ...
}:
{
  sops.secrets."fullchain.pem" = {
    sopsFile = ./secrets/certs.yaml;
    key = "fullchain";
    owner = "caddy";
    group = "caddy";
  };
  sops.secrets."privkey.pem" = {
    sopsFile = ./secrets/certs.yaml;
    key = "privkey";
    owner = "caddy";
    group = "caddy";
  };
  services.caddy = {
    enable = true;
    virtualHosts."test.mrbl.dedyn.io" = {
      extraConfig = ''
        tls ${config.sops.secrets."fullchain.pem".path} \
            ${config.sops.secrets."privkey.pem".path}

        reverse_proxy localhost

        respond OK
      '';
    };
  };
}
