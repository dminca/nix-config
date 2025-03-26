{
  ...
}:
{
  nixpkgs.hostPlatform = "x86_64-darwin";
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
    ];
  };
}

