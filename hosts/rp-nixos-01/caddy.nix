{
  ...
}:
{
  services.caddy = {
    enable = true;
    virtualHosts."localhost" = {
      extraConfig = ''
        respond OK
      '';
    };
  };
}
