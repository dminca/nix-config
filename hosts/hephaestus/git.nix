{
  config,
  ...
}:
let
  gitCredentialsPath = config.sops.templates."git-credentials".path;
in
{
  sops.secrets.codeberg = {
    sopsFile = ./secrets/gitconfig_identities.yaml;
    key = "codeberg";
  };

  sops.secrets.gitlab = {
    sopsFile = ./secrets/gitconfig_identities.yaml;
    key = "gitlab";
  };

  sops.secrets.github = {
    sopsFile = ./secrets/gitconfig_identities.yaml;
    key = "github";
  };

  sops.secrets.github-token = {
    sopsFile = ./secrets/git-tokens.yaml;
    key = "github";
  };

  sops.secrets.gitlab-token = {
    sopsFile = ./secrets/git-tokens.yaml;
    key = "gitlab";
  };

  sops.secrets.codeberg-token = {
    sopsFile = ./secrets/git-tokens.yaml;
    key = "codeberg";
  };

  sops.templates."git-credentials" = {
    content = ''
      https://dminca:${config.sops.placeholder.github-token}@github.com
      https://dminca:${config.sops.placeholder.gitlab-token}@gitlab.com
      https://dminca:${config.sops.placeholder.codeberg-token}@codeberg.org
    '';
    mode = "0600";
  };

  programs.git = {
    settings = {
      credential.helper = "store --file ${gitCredentialsPath}";
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
