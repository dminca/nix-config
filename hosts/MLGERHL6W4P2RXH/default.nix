{
  ...
}:
{
  imports = [
    ./home.nix
    ./vscode.nix
    ./git.nix
    ./zshrc.nix
  ];

  profiles.shell.zsh.enable = true;
  profiles.common.hunk.enable = true;
}
