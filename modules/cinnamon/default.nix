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

  config = lib.mkIf cfg.enable {
    services.xserver.desktopManager.cinnamon = {
      enable = true;
      inherit (cfg) sessionPath extraGSettingsOverrides extraGSettingsOverridePackages;
    };

    services.cinnamon.apps.enable = cfg.apps.enable;
    services.displayManager.defaultSession = cfg.defaultSession;
    services.xserver.displayManager.lightdm.enable = cfg.lightdm.enable;
    services.xserver.displayManager.lightdm.greeters.slick.enable = lib.mkForce false;

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
