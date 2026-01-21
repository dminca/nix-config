{
  config,
  ...
}:
{
  programs.git = {
    settings = {
      includeIf."gitdir:${config.home.homeDirectory}/Projects/misc/" = {
        path = config.sops.secrets.github.path;
      };
      includeIf."gitdir:${config.home.homeDirectory}/Projects/codeberg.org/" = {
        path = config.sops.secrets.codeberg.path;
      };
      includeIf."gitdir:${config.home.homeDirectory}/Projects/github.com/" = {
        path = config.sops.secrets.github.path;
      };
      includeIf."gitdir:${config.home.homeDirectory}/Projects/gitlab.com/" = {
        path = config.sops.secrets.gitlab.path;
      };
    };
  };
}
