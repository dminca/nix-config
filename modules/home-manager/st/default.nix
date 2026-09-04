{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.profiles.common.st;
  tmuxCfg = config.profiles.common.tmux;
  baseCommand = "${lib.getExe pkgs.st} -f '${cfg.font}:size=${toString cfg.fontSize}'";
  tmuxCommand = "${lib.getExe pkgs.tmux} new-session -A -s main";
in
{
  options.profiles.common.st = {
    enable = lib.mkEnableOption "shared Home Manager st profile";

    font = lib.mkOption {
      type = lib.types.str;
      default = "JetBrainsMono Nerd Font";
      description = "Font family used by st.";
    };

    fontSize = lib.mkOption {
      type = lib.types.int;
      default = 11;
      description = "Font size used by st.";
    };

    command = lib.mkOption {
      type = lib.types.str;
      default =
        if tmuxCfg.enable && tmuxCfg.launchOnTerminalOpen then
          "${baseCommand} -e ${tmuxCommand}"
        else
          baseCommand;
      description = "Computed terminal command for launching st.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.st ];

    home.sessionVariables = {
      TERMINAL = "st";
    };
  };
}
