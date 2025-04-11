{
  ...
}:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };
    casks = [
      {
        name = "mullvadvpn";
        greedy = true;
      }
      {
        name = "orion";
        greedy = true;
      }
    ];
  };
}
