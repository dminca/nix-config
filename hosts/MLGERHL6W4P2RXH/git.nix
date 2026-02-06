{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.git = {
    package = pkgs.git.override { osxkeychainSupport = false; };
    includes = [
      {
        condition = "gitdir:${config.home.homeDirectory}/Projects/misc/";
        path = config.sops.secrets.work.path;
      }
      {
        condition = "gitdir:${config.home.homeDirectory}/Projects/codeberg.org/";
        path = config.sops.secrets.opensource.path;
      }
      {
        condition = "gitdir:${config.home.homeDirectory}/Projects/github.com/dminca/";
        path = config.sops.secrets.opensource.path;
      }
      {
        condition = "gitdir:${config.home.homeDirectory}/Projects/github.com/work-gh/";
        path = config.sops.secrets.ghent.path;
      }
      {
        condition = "gitdir:${config.home.homeDirectory}/Projects/gitlab.com/";
        path = config.sops.secrets.opensource.path;
      }
    ];
    settings = {
      credential = {
        helper = lib.mkForce "store --file=${config.sops.secrets.workc.path}";
      };
      include = {
        path = config.sops.secrets.additionalGitconfig.path;
      };
      "url \"https://\"" = {
        insteadOf = [
          "ssh://"
          "git://"
        ];
      };
      push = {
        autoSetupRemote = true;
      };
    };
  };
}
