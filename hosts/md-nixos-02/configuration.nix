{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./sneeky.nix
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
  # /mnt/arr-data is a Proxmox-managed LXC mountpoint and should not be
  # restarted by NixOS unit reactivation.
  systemd.suppressedSystemUnits = [
    "sys-kernel-debug.mount"
    "mnt-arr\\x2ddata.mount"
  ];

  # ── Networking ────────────────────────────────────────────────────────────
  networking = {
    hostName = "md-nixos-02";
    useDHCP = lib.mkDefault true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        80
        443
# Explicit app ports used by the Caddy reverse proxy on rp-nixos-01.
        9696 # prowlarr
        8080 # qbittorrent Web UI
        111  # NFS portmapper
        2049 # NFS
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
