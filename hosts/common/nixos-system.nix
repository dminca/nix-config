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
}

