{
  ...
}:
{
  sops.secrets.fullchain = {
    sopsFile = ./secrets/certs.yaml;
    key = "fullchain";
    owner = "caddy";
    group = "caddy";
    path = "/var/lib/caddy/certs/fullchain.pem";
  };
  sops.secrets.privkey = {
    sopsFile = ./secrets/certs.yaml;
    key = "privkey";
    owner = "caddy";
    group = "caddy";
    path = "/var/lib/caddy/certs/privkey.pem";
    mode = "0400";
  };
  services.caddy = {
    enable = true;
    virtualHosts."test.mrbl.dedyn.io" = {
      extraConfig = ''
        test.mrbl.dedyn.io {
            tls /var/lib/caddy/certs/fullchain.pem \
                /var/lib/caddy/certs/privkey.pem

            reverse_proxy localhost
        }
      '';
    };
  };
}
