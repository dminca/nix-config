{
  ...
}:
{
  imports = [
    ./home.nix
    ./tmux.nix
  ];

  profiles.common.shell.enable = true;
  profiles.common.git.enable = true;
  profiles.common.wezterm.enable = true;
  programs.nvix.enable = true;
}
