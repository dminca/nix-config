{
  ...
}:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "mida4001";
  system.defaults.CustomUserPreferences = {
    "NSGlobalDomain" = {
      NSIdleDisplaySleepInterval = 0; # "Never"
    };
  };
  system.defaults.screensaver = {
    askForPassword = true;
    askForPasswordDelay = 14400;
  };
  homebrew = {
    casks = [
      {
        name = "visual-studio-code";
        greedy = true;
      }
      {
        name = "krita";
        greedy = true;
      }
      {
        name = "orchard";
        greedy = true;
      }
    ];
  };
}
