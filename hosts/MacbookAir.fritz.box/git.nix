{
  config,
  ...
}:
{
  programs.git = {
    enable = true;
    delta.enable = true;
    extraConfig = {
      includeIf."gitdir:${config.home.homeDirectory}/Projects/misc/" = {
        path = "${config.xdg.configHome}/git/github";
      };
      includeIf."gitdir:${config.home.homeDirectory}/Projects/codeberg.org/" = {
        path = "${config.xdg.configHome}/git/codeberg";
      };
      includeIf."gitdir:${config.home.homeDirectory}/Projects/github.com/" = {
        path = "${config.xdg.configHome}/git/github";
      };
      includeIf."gitdir:${config.home.homeDirectory}/Projects/gitlab.com/" = {
        path = "${config.xdg.configHome}/git/gitlab";
      };
    };
  };
}
