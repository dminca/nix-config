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
        name = "filen";
        greedy = true;
      }
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
        name = "nextcloud-talk";
        greedy = true;
      }
    ];
  };
}
