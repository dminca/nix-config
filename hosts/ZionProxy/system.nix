{
  config,
  ...
}:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "dminca";

  homelab.ziggity.enable = true;
  homelab.radicle-backup.enable = true;
  homelab.ai.hermes = {
    enable = true;
    openrouter.enable = true;
    openrouter.apiKeyFile = config.sops.secrets.openrouter_api_key.path;
  };

  sops.age.keyFile = "/Users/dminca/.config/sops/age/keys.txt";
  sops.secrets.openrouter_api_key = {
    sopsFile = ./secrets/openrouter.yaml;
  };
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
    };
    casks = [
      {
        name = "signal";
        greedy = true;
      }
      {
        name = "nextcloud";
        greedy = true;
      }
      {
        name = "krita";
        greedy = true;
      }
      {
        name = "libreoffice";
        greedy = true;
      }
      {
        name = "kde-connect";
        greedy = true;
      }
    ];
  };
}
