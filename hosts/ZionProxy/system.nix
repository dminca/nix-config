{
  ...
}:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "dminca";

  homelab.ziggity.enable = true;
  homelab.radicle-backup.enable = true;
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
    };
    casks = [
      {
        name = "signal";
        greedy = true;
      }
      {
        name = "nextcloud";
        greedy = true;
      }
      {
        name = "krita";
        greedy = true;
      }
      {
        name = "libreoffice";
        greedy = true;
      }
      {
        name = "kde-connect";
        greedy = true;
      }
    ];
  };
}
