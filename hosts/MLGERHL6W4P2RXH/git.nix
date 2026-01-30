{
  config,
  ...
}:
{
  programs.git = {
#     To have this happen automatically for branches without a tracking
# upstream, see 'push.autoSetupRemote' in 'git help config'.
    settings = {
      includeIf."gitdir:${config.home.homeDirectory}/Projects/misc/" = {
        path = config.sops.secrets.work.path;
      };
      includeIf."gitdir:${config.home.homeDirectory}/Projects/codeberg.org/" = {
        path = config.sops.secrets.opensource.path;
      };
      includeIf."gitdir:${config.home.homeDirectory}/Projects/github.com/" = {
        path = config.sops.secrets.opensource.path;
      };
      includeIf."gitdir:${config.home.homeDirectory}/Projects/gitlab.com/" = {
        path = config.sops.secrets.opensource.path;
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
