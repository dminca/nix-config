{
  config,
  ...
}:
{
  programs.git = {
#     To have this happen automatically for branches without a tracking
# upstream, see 'push.autoSetupRemote' in 'git help config'.
    extraConfig = {
      includeIf."gitdir:${config.home.homeDirectory}/Projects/misc/" = {
        path = "${config.xdg.configHome}/git/identity_work";
      };
      includeIf."gitdir:${config.home.homeDirectory}/Projects/codeberg.org/" = {
        path = "${config.xdg.configHome}/git/identity_opensource";
      };
      includeIf."gitdir:${config.home.homeDirectory}/Projects/github.com/" = {
        path = "${config.xdg.configHome}/git/identity_opensource";
      };
      includeIf."gitdir:${config.home.homeDirectory}/Projects/gitlab.com/" = {
        path = "${config.xdg.configHome}/git/identity_opensource";
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
