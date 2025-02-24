{
  ...
}:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  nix.enable = false;
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };
    casks = [
      "notion"
      "mullvadvpn"
    ];
  };
}
