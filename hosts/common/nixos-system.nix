{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    neovim
  ];
  nix.settings.experimental-features = "nix-command flakes";
  programs.zsh.enable = true;
}

