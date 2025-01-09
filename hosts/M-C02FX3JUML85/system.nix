{
  ...
}:
{
  nixpkgs.hostPlatform = "x86_64-darwin";
  homebrew = {
    casks = [
      "slack"
      {
        name = "krita";
        greedy = true;
      }
      {
        name = "microsoft-teams";
        greedy = true;
      }
    ];
  };
}

