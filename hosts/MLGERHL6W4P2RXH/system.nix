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
    enable = true;
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };
    casks = [
      {
        name = "vivaldi";
        greedy = true;
      }
    ];
  };
}

