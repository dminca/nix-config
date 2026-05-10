{
  config,
  ...
}:
{
  home.stateVersion = "25.11";
  sops = {
    defaultSopsFile = ./secrets/example.yaml;
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
  };
}
