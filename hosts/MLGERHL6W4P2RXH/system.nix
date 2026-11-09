{
  ...
}:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "mida4001";
  homelab.ziggity.enable = true;
  homelab.bramble.enable = false;
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
        name = "krita";
        greedy = true;
      }
      {
        name = "kde-connect";
        greedy = true;
      }
      {
        name = "libreoffice";
        greedy = true;
      }
      {
        name = "bramble";
        greedy = true;
      }
      {
        name = "zed";
        greedy = true;
      }
    ];
  };
}
