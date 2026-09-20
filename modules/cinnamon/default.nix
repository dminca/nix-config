{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.profiles.desktop.cinnamon;
in
{
  options.profiles.desktop.cinnamon = {
    enable = lib.mkEnableOption "Cinnamon desktop profile";

    user = lib.mkOption {
      type = lib.types.str;
      default = "dminca";
      description = "Home Manager user that receives Cinnamon session configuration.";
    };

    defaultSession = lib.mkOption {
      type = lib.types.str;
      default = "cinnamon";
      description = "Display manager session name used as the default login session.";
    };

    lightdm.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to keep LightDM enabled for Cinnamon logins.";
    };

    apps.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable Cinnamon default applications and desktop services.";
    };

    sessionPath = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra packages added to the Cinnamon session search path.";
    };

    extraGSettingsOverrides = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra Cinnamon gsettings overrides.";
    };

    extraGSettingsOverridePackages = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Packages whose gsettings overrides should be applied to Cinnamon.";
    };

    excludePackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Packages to remove from the Cinnamon default environment.";
    };
  };

  # NOTE: This module intentionally does NOT reference `home-manager.*`.
  # It's imported globally (modules/default.nix) on every host, including
  # ones that never wire in the Home Manager NixOS module (e.g.
  # hs-nixos-01, mon-nixos-01). Referencing `home-manager.users.*` here —
  # even behind `lib.mkIf`/`lib.optionalAttrs`/`options ? home-manager`
  # guards — either trips the "option does not exist" check (mkIf only
  # defers the *value*, not the attribute key) or causes infinite
  # recursion (checking `options ? home-manager` forces the full options
  # fixed-point, which cycles back through this same module). The actual
  # Home Manager wiring for Cinnamon lives per-host in flake.nix's
  # `extraModules`, right next to where Home Manager itself is enabled —
  # see the `hephaestus` host entry.
  config = lib.mkIf cfg.enable {
    services.xserver = {
      xkb = {
        layout = "us,ro";
        variant = ",std";
        options = "caps:escape";
      };
      autoRepeatDelay = 233;
      autoRepeatInterval = 17;
    };
    console.useXkbConfig = true;
    services.xserver.desktopManager.cinnamon = {
      enable = true;
      inherit (cfg) sessionPath extraGSettingsOverrides extraGSettingsOverridePackages;
    };

    services.cinnamon.apps.enable = cfg.apps.enable;
    services.displayManager.defaultSession = cfg.defaultSession;
    services.xserver.displayManager.lightdm.enable = cfg.lightdm.enable;
    security.pam.services.cinnamon-screensaver = {
      fprintAuth = true;
      unixAuth = true;
    };

    environment.cinnamon.excludePackages = cfg.excludePackages;

    environment.sessionVariables = {
      XDG_CURRENT_DESKTOP = "X-Cinnamon";
      XDG_SESSION_DESKTOP = "cinnamon";
      XDG_SESSION_TYPE = "x11";
    };

    programs.dconf.enable = true;
    services.gnome.gnome-keyring.enable = true;
    services.gnome.gcr-ssh-agent.enable = true;
    security.polkit.enable = true;

    services.xserver.updateDbusEnvironment = true;
    services.gvfs.enable = true;
    services.udisks2.enable = true;
    services.power-profiles-daemon.enable = true;
    services.switcherooControl.enable = true;
    services.libinput.enable = true;
    services.accounts-daemon.enable = true;

    services.dbus.packages = with pkgs; [
      cinnamon
      cinnamon-screensaver
      nemo-with-extensions
      xapp
    ];
  };
}

