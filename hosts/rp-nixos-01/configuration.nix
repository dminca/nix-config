{
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./caddy.nix
  ];
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  # ── Boot ──────────────────────────────────────────────────────────────────
  boot = {
    # Proxmox LXC containers do not own the host boot process.
    isContainer = true;
    loader.grub.enable = lib.mkForce false;
    loader.systemd-boot.enable = lib.mkForce false;
  };

  # debugfs cannot be mounted in unprivileged LXC containers.
  systemd.suppressedSystemUnits = [ "sys-kernel-debug.mount" ];

  homelab.monitoring.agent.enable = true;
  homelab.monitoring.agent.extraScrapeConfigs = [
    {
      job_name = "caddy-json";
      journal = {
        max_age = "12h";
        labels = {
          job = "caddy-json";
          host = "rp-nixos-01";
          cluster = "homelab";
        };
      };
      relabel_configs = [
        {
          source_labels = [ "__journal__systemd_unit" ];
          regex = "caddy\\.service";
          action = "keep";
        }
        {
          source_labels = [ "__journal__systemd_unit" ];
          target_label = "unit";
        }
      ];
      pipeline_stages = [
        {
          json = {
            expressions = {
              level = "level";
              logger = "logger";
              msg = "msg";
              request_host = "request>host";
              request_method = "request>method";
              request_uri = "request>uri";
              status = "status";
              duration = "duration";
            };
          };
        }
        {
          labels = {
            level = null;
            logger = null;
            request_host = null;
            request_method = null;
            status = null;
          };
        }
      ];
    }
  ];
  # ── Networking ────────────────────────────────────────────────────────────
  networking = {
    hostName = "rp-nixos-01";
    useDHCP = lib.mkDefault true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        80
        443
      ];
    };
  };

  # ── SSH ───────────────────────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # ── Users ─────────────────────────────────────────────────────────────────
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINuhmI6QfT3B6wMs7FaQClAtlEa2KHbW/fKFXvzE2+kX dminca@ZionProxy-2025-08-20"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # ── Base packages ─────────────────────────────────────────────────────────
  environment.systemPackages = map lib.lowPrio [
    pkgs.gitMinimal
    pkgs.vim
    pkgs.htop
    pkgs.curl
    pkgs.tmux
  ];

  # ── Misc ──────────────────────────────────────────────────────────────────
  time.timeZone = "UTC";
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
  ];
  i18n.defaultLocale = "en_US.UTF-8";
  services.qemuGuest.enable = true;
  # ── SOPS (Secrets Operation) ──────────────────────────────────────────────
  sops = {
    defaultSopsFile = ./secrets/example.yaml;
    age.keyFile = "/home/admin/.config/sops/age/keys.txt";
  };

  system.stateVersion = "25.11";
}

