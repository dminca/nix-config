{
  config,
  ...
}:
{
  programs.zsh = {
    initExtra = ''
      gpg-connect-agent updatestartuptty /bye > /dev/null
      export VAULT_ADDR="https://$(cat ${config.sops.secrets.sman.path})";
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
    };
  };
}
