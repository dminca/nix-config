{
  ...
}:
{
  imports = [
    ./home.nix
    ./git.nix
  ];

  profiles.shell.zsh.enable = true;
}
