{
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./caddy.nix
    ../common/monitoring-agent.nix
    ../common/monitoring-server.nix
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

  homelab.monitoring = {
    agent.enable = true;
    server = {
      enable = true;
      scrapeTargets = [
        "rp-nixos-01:9100"
        "hm-nixos-01:9100"
        "nc-nixos-01:9100"
        "kc-nixos-01:9100"
        "lw-nixos-01:9100"
        "ic-nixos-01:9100"
      ];
      dashboardFiles = [
        ../common/grafana-dashboards/node-overview.json
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
