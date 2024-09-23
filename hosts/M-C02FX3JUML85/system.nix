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
      {
        name = "microsoft-teams";
        greedy = true;
      }
      "hot"
      "notion"
      "slack"
      {
        name = "firefox";
        greedy = true;
      }
      {
        name = "krita";
        greedy = true;
      }
    ];
  };
}

