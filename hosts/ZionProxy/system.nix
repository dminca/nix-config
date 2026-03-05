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
      {
        name = "mullvad-vpn";
        greedy = true;
      }
    ];
  };
}
