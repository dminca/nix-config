# modules/base.nix
# Shared configuration applied to every VM image.
# Host-specific concerns (hostname, static IP, extra services) belong in
# hosts/<name>/configuration.nix instead.
{
  config,
  pkgs,
  lib,
  ...
}:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  # ── Boot ──────────────────────────────────────────────────────────────────
#  boot.loader.grub = {
#    enable = true;
#    device = "/dev/sda"; # proxmox image format uses virtio-scsi → /dev/sda
#    efiSupport = false; # Proxmox defaults to SeaBIOS; flip to true + add efiSysMountPoint for OVMF
#  };

  # ── Disk image size ───────────────────────────────────────────────────────
  # Controls the size of the generated disk image (in MiB).
  # This is the canonical option (proxmox.qemuConf.diskSize was renamed here).
  virtualisation.diskSize = lib.mkDefault 8192; # 8 GiB

  # ── Filesystem ────────────────────────────────────────────────────────────
  # The image builder handles disk partitioning; this just sets the label.
  fileSystems."/" = lib.mkDefault {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  # ── Networking ────────────────────────────────────────────────────────────
  networking = {
    # Each host overrides networking.hostName in its own configuration.nix.
    useDHCP = lib.mkDefault true;

    # Optionally enable firewall — hosts can open specific ports.
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
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
  # A single admin user is baked in.  Add your own public key here.
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

  system.stateVersion = "25.11";
}
