{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.profiles.desktop.i3;
in
{
  options.profiles.desktop.i3 = {
    enable = lib.mkEnableOption "i3 desktop profile";

    user = lib.mkOption {
      type = lib.types.str;
      default = "dminca";
      description = "Home Manager user that receives i3 session configuration.";
    };

    wallpaperStateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/${config.networking.hostName}-wallpaper";
      description = ''
        Directory holding the stable "current" wallpaper symlink.
        Owned by `user`, read by the LightDM greeter background and by
        i3lock via the Home Manager i3 module's `wallpaperCurrentPath`.
      '';
    };
  };

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
    services.xserver.windowManager.i3.enable = true;
    services.displayManager.defaultSession = "none+i3";
    security.pam.services.i3lock = {
      fprintAuth = true;
      unixAuth = true;
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

    environment.systemPackages = with pkgs; [ feh thunar ];

    services.dbus.packages = with pkgs; [
      i3
      i3lock
    ];

    services.xserver.displayManager.lightdm.greeters.gtk.extraConfig = ''
      background = ${cfg.wallpaperStateDir}/current
    '';

    systemd.tmpfiles.rules = [
      "d ${cfg.wallpaperStateDir} 0755 ${cfg.user} users -"
    ];
  };
}
