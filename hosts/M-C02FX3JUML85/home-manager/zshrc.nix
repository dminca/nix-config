{ config, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    history = {
      size = 10000000;
      save = 10000000;
      ignoreSpace = true;
      ignoreDups = true;
      ignoreAllDups = true;
      expireDuplicatesFirst = true;
      extended = true;
      share = true;
      path = "${config.home.homeDirectory}/.zsh_history";
    };
    initExtra = ''
      gpg-connect-agent updatestartuptty /bye > /dev/null
      export VAULT_ADDR="https://$(cat ${config.sops.secrets.sman.path})";
    '';
    profileExtra = ''
      setopt BANG_HIST                 # Treat the '!' character specially during expansion.
      setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
      setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
      setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
      setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
      setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
      setopt HIST_BEEP                 # Beep when accessing nonexistent history.
      eval "$($(which brew) shellenv)" # Set PATH, MANPATH, etc., for Homebrew.
    '';
    shellAliases = {
      k = "kubectl";
      kgno = "kubectl get nodes";
      kgp = "kubectl get pods";
      kgd = "kubectl get deployment";
      kgda = "kubectl get deployment --all-namespaces";
      klf = "kubectl logs -f";
      kdel = "kubectl delete";
      kgi = "kubectl get ingress";
      kgia = "kubectl get ingress --all-namespaces";
      g = "git";
      gaa = "git add --all";
      gcs = "git commit -s -v";
      gb = "git branch";
      gba = "git branch -a";
      gsw = "git branch | gum choose | xargs git switch";
      gswc = "git switch -c";
      gss = "git status -s";
      gst = "git status";
      gco = "git checkout";
      glol = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'";
      glols = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --stat";
      glod = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'";
      glods = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset' --date=short";
      glola = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --all";
      glog = "git log --oneline --decorate --graph";
      gloga = "git log --oneline --decorate --graph --all";
      gpv = "git push -v";
      gl = "git pull";
      gd = "git diff";
      gds = "git diff --staged";
      gdt = "git diff-tree --no-commit-id --name-only -r";
      gdw = "git diff --word-diff";
      gwch = "git whatchanged -p --abbrev-commit --pretty=medium";
      "gca!" = "git commit -v -a --amend";
      gmt = "git mergetool --no-prompt";
      grba = "git rebase --abort";
      grbc = "git rebase --continue";
      gbd = "git branch | gum choose --no-limit | xargs git branch -D";
    };
  };
}
