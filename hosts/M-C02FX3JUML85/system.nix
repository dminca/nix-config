{
  ...
}:
{
  nixpkgs.hostPlatform = "x86_64-darwin";
  homebrew = {
    casks = [
      {
        name = "microsoft-teams";
        greedy = true;
      }
      "slack"
      {
        name = "krita";
        greedy = true;
      }
    ];
  };
}

