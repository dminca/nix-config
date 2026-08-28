{
  modulesPath,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  username = "dminca";
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  networking.hostName = "hephaestus";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "ro_RO.UTF-8/UTF-8"
    "de_DE.UTF-8/UTF-8"
  ];

  services.xserver = {
    xkb = {
      layout = "us";
    };
  };
  console.useXkbConfig = true;

  services.libinput.enable = true;
  services.fprintd.enable = true;

  security.pam.services.sudo = {
    fprintAuth = true;
    unixAuth = true;
  };
  security.pam.services.hyprlock = {
    # hyprlock handles fingerprint natively; keep PAM for password fallback.
    unixAuth = true;
  };
  security.sudo.wheelNeedsPassword = true;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINuhmI6QfT3B6wMs7FaQClAtlEa2KHbW/fKFXvzE2+kX dminca@ZionProxy-2025-08-20"
    ];
  };

  programs.zsh.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = username;
        command = "${lib.getExe pkgs.tuigreet} --time --remember --cmd 'uwsm start hyprland.desktop'";
      };
    };
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
    configPackages = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vpl-gpu-rt
    ];
  };

  services.fstrim.enable = true;
  zramSwap.enable = true;
  services.thermald.enable = true;
  powerManagement.powertop.enable = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  services.getty.autologinUser = "dminca";
  programs.kdeconnect.enable = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    trusted-users = [ username ];
  };
  nixpkgs.config.allowUnfree = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
    nh
    foot
    wezterm
    fprintd
    signal-desktop
    nextcloud-client
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.${username} = import ./home.nix;
  };

  system.stateVersion = "26.05";
}
