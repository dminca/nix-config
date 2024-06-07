{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.username = "DanielAndrei.Minca";
  home.homeDirectory = "/Users/DanielAndrei.Minca";
  home.stateVersion = "23.11";
  home.packages = with pkgs; [
    #################
    # shell tooling #
    #################
    python3
    pinentry_mac
    rsync
    tcptraceroute
    viddy # watch replacement
    pre-commit
    glab
    ########################
    # cloud-native tooling #
    ########################
    kubectl
    kubernetes-helm
    kubectx
    krew
    sloth
    hugo
    jq
    jsonnet
    jsonnet-bundler
    terraform
    tfswitch
    vault
    google-cloud-sdk
    s3cmd
    kustomize_4
    kubeseal
    kubelogin-oidc
    minio-client
    colima
    docker-client
    helm-ls
    helm-docs
    kluctl
    ########
    # Apps #
    ########
    drawio
    postman
    wireshark
    cyberduck
    maccy
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
    path = "${config.xdg.configHome}/git/identity_work";
  };
  sops.secrets.opensource = {
    sopsFile = ./secrets/gitconfig_identities.yaml;
    path = "${config.xdg.configHome}/git/identity_opensource";
  };
  sops.secrets.additionalNvimconfig = {
    sopsFile = ./secrets/neovim.yaml;
  };
  sops.secrets.additionalGitconfig = {
    sopsFile = ./secrets/fqdns.yaml;
  };
  sops.secrets.sman = {
    sopsFile = ./secrets/sman.yaml;
  };
  sops.secrets.glab = {
    sopsFile = ./secrets/config.yml;
    path = "${config.xdg.configHome}/glab-cli/config.yml";
  };

  home.file = {
    ".gnupg/gpg-agent.conf".text = ''
      default-cache-ttl 600
      max-cache-ttl 7200
      pinentry-program ${lib.getExe pkgs.pinentry_mac}
      enable-ssh-support
    '';
  };

  home.sessionVariables = {
    GPG_TTY = "$(tty)";
    GOPATH = "${config.home.homeDirectory}/Repos/open-source/others/gopath";
    SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.krew/bin"
  ];

  programs.direnv.enable = true;
  programs.java.enable = true;
  programs.gpg = {
    enable = true;
    settings = {
      auto-key-retrieve = true;
      no-emit-version = true;
      default-key = "D02DE2B3DF391A132A379A1EEACCEEE9CC3C8E69";
      use-agent = false;
      no-tty = false;
    };
  };
  programs.go = {
    goPath = "Repos/open-source/others/gopath";
  };
  programs.k9s = {
    enable = true;
    settings = {
      k9s = {
        refreshRate = 2;
        ui = {
          headless = true;
          skin = "catppuccin-mocha-transparent";
        };
      };
    };
    skins = {
      catppuccin-mocha-transparent = {
        k9s = {
          body = {
            fgColor = "#cdd6f4";
            bgColor = "default";
            logoColor = "#cba6f7";
          };
          prompt = {
            fgColor = "#cdd6f4";
            bgColor = "default";
            suggestColor = "#89b4fa";
          };
          help = {
            fgColor = "#cdd6f4";
            bgColor = "default";
            sectionColor = "#a6e3a1";
            keyColor = "#89b4fa";
            numKeyColor = "#eba0ac";
          };
          frame = {
            title = {
              fgColor = "#94e2d5";
              bgColor = "default";
              highlightColor = "#f5c2e7";
              counterColor = "#f9e2af";
              filterColor = "#a6e3a1";
            };
            border = {
              fgColor = "#cba6f7";
              focusColor = "#b4befe";
            };
            menu = {
              fgColor = "#cdd6f4";
              keyColor = "#89b4fa";
              numKeyColor = "#eba0ac";
            };
            crumbs = {
              fgColor = "#1e1e2e";
              bgColor = "default";
              activeColor = "#f2cdcd";
            };
            status = {
              newColor = "#89b4fa";
              modifyColor = "#b4befe";
              addColor = "#a6e3a1";
              pendingColor = "#fab387";
              errorColor = "#f38ba8";
              highlightColor = "#89dceb";
              killColor = "#cba6f7";
              completedColor = "#6c7086";
            };
          };
          info = {
            fgColor = "#fab387";
            sectionColor = "#cdd6f4";
          };
          views = {
            table = {
              fgColor = "#cdd6f4";
              bgColor = "default";
              cursorFgColor = "#313244";
              cursorBgColor = "#45475a";
              markColor = "#f5e0dc";
              header = {
                fgColor = "#f9e2af";
                bgColor = "default";
                sorterColor = "#89dceb";
              };
            xray = {
              fgColor = "#cdd6f4";
              bgColor = "default";
              cursorColor = "#45475a";
              cursorTextColor = "#1e1e2e";
              graphicColor = "#f5c2e7";
            };
            charts = {
              bgColor = "default";
              chartBgColor = "default";
              dialBgColor = "default";
              defaultDialColors = [
                "#a6e3a1"
                "#f38ba8"
              ];
              defaultChartColors = [
                "#a6e3a1"
                "#f38ba8"
              ];
              resourceColors = {
                cpu = [
                  "#cba6f7"
                  "#89b4fa"
                ];
                mem = [
                  "#f9e2af"
                  "#fab387"
                ];
                };
              };
            };
            yaml = {
              keyColor = "#89b4fa";
              valueColor = "#cdd6f4";
              colonColor = "#a6adc8";
            };
            logs = {
              fgColor = "#cdd6f4";
              bgColor = "default";
              indicator = {
                fgColor = "#b4befe";
                bgColor = "default";
                toggleOnColor = "#a6e3a1";
                toggleOffColor = "#a6adc8";
              };
            };
          };
          dialog = {
            fgColor = "#f9e2af";
            bgColor = "default";
            buttonFgColor = "#1e1e2e";
            buttonBgColor = "default";
            buttonFocusFgColor = "#1e1e2e";
            buttonFocusBgColor = "#f5c2e7";
            labelFgColor = "#f5e0dc";
            fieldFgColor = "#cdd6f4";
          };
        };
      };
    };
  };
  programs.powerline-go = {
    modules = [
      "kube"
    ];
  };
}
