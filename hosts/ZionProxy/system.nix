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
        name = "deepl";
        greedy = true;
      }
      {
        name = "signal";
        greedy = true;
      }
      {
        name = "sw33tlie/macshot/macshot";
        greedy = true;
      }
    ];
  };
}
