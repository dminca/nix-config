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

