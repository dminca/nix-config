{
  config,
  ...
}:
{
  programs.git = {
    enable = true;
    delta.enable = true;
    extraConfig = {
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
        tool = "opendiff";
      };
      difftool = {
        prompt = false;
      };
      mergetool = {
        prompt = false;
        keepBackup = false;
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
      ".idea"
      ".vscode"
    ];
  };
}

