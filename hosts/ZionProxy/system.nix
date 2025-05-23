{
  ...
}:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "dminca";
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };
    casks = [
      {
        name = "orion";
        greedy = true;
      }
      {
        name = "signal";
        greedy = true;
      }
      {
        name = "filen";
        greedy = true;
      }
    ];
  };
}
