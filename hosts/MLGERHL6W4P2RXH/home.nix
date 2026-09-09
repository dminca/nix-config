{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  home.username = "mida4001";
  home.homeDirectory = "/Users/mida4001";
  home.stateVersion = "23.11";
  programs.nvix.enable = true;
  home.packages = with pkgs; [
    #################
    # shell tooling #
    #################
    pinentry_mac
    rsync
    viddy # watch replacement
    pre-commit
    glab
    devenv
    jsonnet
    jsonnet-bundler
    gojsontoyaml
    jsonnet-language-server
    yaml-language-server
    github-copilot-cli
    jira-cli-go
    rustup
    cue
    gh
    fluxcd
    just
    istioctl
    witr
    popeye
    inputs.sofka.packages.${pkgs.stdenv.hostPlatform.system}.default
    ########################
    # cloud-native tooling #
    ########################
    kubectl
    kubectl-neat
    kubectl-images
    kubernetes-helm
    kubectx
    sloth
    kustomize_4
    kubeseal
    kubelogin-oidc
    minio-client
    helm-ls
    helm-docs
    fx
    (google-cloud-sdk.withExtraComponents [ google-cloud-sdk.components.gke-gcloud-auth-plugin ])
    opentofu
    tofu-ls
    terraform
    terraform-ls
    terraform-docs
    tflint
    crane
    kluctl
    vault
    container
    ########
    # Apps #
    ########
    jetbrains.idea
    drawio
  ];

  sops = {
    defaultSopsFile = ./secrets/example.yaml;
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
  };
  sops.secrets.gitlab_isi_prd_full = {
    sopsFile = ./secrets/s3configs.yaml;
    path = "${config.xdg.configHome}/s3cfg/gitlab_isi_prd_full";
  };
  sops.secrets.gitlab_isi_prd_small = {
    sopsFile = ./secrets/s3configs.yaml;
    path = "${config.xdg.configHome}/s3cfg/gitlab_isi_prd_small";
  };
  sops.secrets.gitlab_isi_stg_small = {
    sopsFile = ./secrets/s3configs.yaml;
    path = "${config.xdg.configHome}/s3cfg/gitlab_isi_stg_small";
  };
  sops.secrets.fr7_etcd_bak_small = {
    sopsFile = ./secrets/s3configs.yaml;
    path = "${config.xdg.configHome}/s3cfg/fr7_etcd_bak_small";
  };
  sops.secrets.fr7_full = {
    sopsFile = ./secrets/s3configs.yaml;
    path = "${config.xdg.configHome}/s3cfg/fr7_full";
  };
  sops.secrets.work = {
    sopsFile = ./secrets/gitconfig_identities.yaml;
    key = "work";
  };
  sops.secrets.ghent = {
    sopsFile = ./secrets/gitconfig_identities.yaml;
    key = "ghent";
  };
  sops.secrets.workc = {
    sopsFile = ./secrets/gitconfig_identities.yaml;
    key = "workc";
  };
  sops.secrets.opensource = {
    sopsFile = ./secrets/gitconfig_identities.yaml;
    path = "${config.xdg.configHome}/git/identity_opensource";
    key = "opensource";
  };
  sops.secrets.additionalGitconfig = {
    sopsFile = ./secrets/fqdns.yaml;
  };
  sops.secrets.sman = {
    sopsFile = ./secrets/sman.yaml;
    key = "";
  };
  sops.secrets.glab = {
    sopsFile = ./secrets/config.yml;
    path = "${config.xdg.configHome}/glab-cli/config.yml";
    mode = "0600";
  };
  sops.secrets.froggo = {
    sopsFile = ./secrets/froggo.yaml;
    key = "virtual";
  };
  sops.secrets.cocojambo = {
    sopsFile = ./secrets/copilot-mcp-secrets.yaml;
    key = "COCOJAMBO";
  };
  sops.secrets.copilot_confluence_personal_token = {
    sopsFile = ./secrets/copilot-mcp-secrets.yaml;
    key = "CONFLUENCE_PERSONAL_TOKEN";
  };
  sops.secrets.copilot_jira_personal_token = {
    sopsFile = ./secrets/copilot-mcp-secrets.yaml;
    key = "JIRA_PERSONAL_TOKEN";
  };

  home.sessionVariables = {
    GOPATH = "${config.home.homeDirectory}/Repos/open-source/others/gopath";
    COCOJAMBO = "$(cat ${config.sops.secrets.cocojambo.path})";
    CONFLUENCE_PERSONAL_TOKEN = "$(cat ${config.sops.secrets.copilot_confluence_personal_token.path})";
    JIRA_PERSONAL_TOKEN = "$(cat ${config.sops.secrets.copilot_jira_personal_token.path})";
  };

  xdg.configFile."sofka/config.toml".text = ''
    favorite_namespaces = ["monitoring"]
  '';

  home.sessionPath = [
    "${config.home.homeDirectory}/.krew/bin"
  ];

  programs.java.enable = true;
  programs.go = {
    env = {
      GOPATH = "Repos/open-source/others/gopath";
      GOPRIVATE = "$(cat ${config.sops.secrets.froggo.path})";
    };
  };
  programs.powerline-go = {
    modules = [
      "kube"
    ];
  };
  programs.jq = {
    enable = true;
  };
  programs.npm = {
    enable = true;
  };
  programs.superfile = {
    enable = true;
  };

  # Ensure vault directory exists for Obsidian app
  home.activation.createObsidianVault = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${config.home.homeDirectory}/Notes/my-vault
  '';
}
