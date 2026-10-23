{
  ...
}:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "dminca";

  homelab.ziggity.enable = true;
  homelab.bramble.enable = false;
  homelab.ai.hermes = {
    enable = false;
    openrouter.enable = true;
  };
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = false;
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
