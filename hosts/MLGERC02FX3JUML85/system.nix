{
  ...
}:
{
  nixpkgs.hostPlatform = "x86_64-darwin";
  system.defaults.NSGlobalDomain.NSIdleDisplaySleepInterval = 0;
  system.defaults.screensaver = {
    askForPassword = true;
    askForPasswordDelay = 14400;
  };
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

