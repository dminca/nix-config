{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    neovim
  ];
  nix.settings.experimental-features = "nix-command flakes";
  nix.enable = false;
  programs.zsh.enable = true;
  system.stateVersion = 4;
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 14;
  system.defaults.NSGlobalDomain.KeyRepeat = 1;
  system.defaults.trackpad.TrackpadThreeFingerVertSwipeGesture = 2;
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };
    casks = [
      "hot"
      "notion"
      {
        name = "deepl";
        greedy = true;
      }

    ];
  };
}

