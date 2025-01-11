{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    neovim
  ];
  services.nix-daemon.enable = true;
  nix.settings.experimental-features = "nix-command flakes";
  programs.zsh.enable = true;
  system.stateVersion = 4;
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 14;
  system.defaults.NSGlobalDomain.KeyRepeat = 1;
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
        name = "firefox";
        greedy = true;
      }
      {
        name = "orion";
        greedy = true;
      }
    ];
  };
}

