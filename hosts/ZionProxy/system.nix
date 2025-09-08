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
        name = "signal";
        greedy = true;
      }
      {
        name = "filen";
        greedy = true;
      }
      {
        name = "vlc";
        greedy = true;
      }
      {
        name = "anytype";
        greedy = true;
      }
      {
        name = "zulip";
        greedy = true;
      }
    ];
  };
}
