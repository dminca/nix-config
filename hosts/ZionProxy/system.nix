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
        name = "deepl";
        greedy = true;
      }
      {
        name = "krita";
        greedy = true;
      }
      {
        name = "zulip";
        greedy = true;
      }
      {
        name = "signal";
        greedy = true;
      }
      {
        name = "session";
        greedy = true;
      }
      {
        name = "simplex";
        greedy = true;
      }
    ];
  };
}
