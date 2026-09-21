{
  ...
}:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "dminca";
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
      {
        name = "balenaetcher";
        greedy = true;
      }
    ];
  };
}
