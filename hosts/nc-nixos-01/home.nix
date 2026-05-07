{
  config,
  ...
}:
{
  home.stateVersion = "23.11";
  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = "${config.xdg.configHome}/sops/age/keys.txt";
  };
  sops = {
    defaultSopsFile = ./secrets/example.yaml;
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
  };
  sops.secrets.nextcloud = {
    sopsFile = ./secrets/nextcloud.yaml;
    key = "password";
    owner = "nextcloud";
  };
}
