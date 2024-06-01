{ config, ... }:
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
      delta = {
        navigate = true;
        side-by-side = true;
      };
      core = {
        editor = "nvim";
        logallrefupdates = true;
        sharedRepository = "0644";
        compression = "9";
      };
      commit = {
        template = "${config.xdg.configHome}/git/git-commit-template.commit";
      };
      color = {
        ui = true;
      };
      push = {
        default = "simple";
      };
      status = {
        submoduleSummary = true;
      };
      diff = {
        submodule = "log";
      };
      merge = {
        log = true;
        tool = "codium";
        conflictstyle = "diff3";
      };
      difftool = {
        prompt = false;
      };
      difftool."codium" = {
        cmd = "codium --wait --diff $LOCAL $REMOTE";
      };
      mergetool."codium" = {
        cmd = "codium --wait $MERGED";
      };
      fetch = {
        recurseSubmodules = "on-demand";
        prune = true;
      };
      receive = {
        fsckObjects = true;
        denyDeletes = true;
        denyDeleteCurrent = true;
        denyCurrentBranch = true;
        denyNonFastForwards = true;
      };
      rebase = {
        stat = true;
      };
      filter."lfs" = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };
    };
    ignores = [
      ".DS_Store"
      "*.pyc"
    ];
  };
}
