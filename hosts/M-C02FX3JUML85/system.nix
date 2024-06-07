{
  ...
}:
{
  nixpkgs.hostPlatform = "x86_64-darwin";
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };
    casks = [
      "microsoft-teams"
      "hot"
      "notion"
      "slack"
      {
        name = "vivaldi";
        greedy = true;
      }
    ];
  };
}

