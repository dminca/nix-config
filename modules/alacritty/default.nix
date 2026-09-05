{
  config,
  lib,
  pkgs,
  ...,
}:
let
  cfg = config.profiles.common.alacritty;
in
{
  options.profiles.common.alacritty = {
    enable = lib.mkEnableOption "Alacritty terminal (via home-manager)";
  };

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        general.live_config_reload = true;
        colors.draw_bold_text_with_bright_colors = true;
        window = {
          opacity = 0.8;
          blur = true;
          padding = {
            x = 2;
            y = 2;
          };
          decorations = "buttonless";
          option_as_alt = "both";
        };
        font = {
          size = 12;
          normal = {
            family = "JetBrainsMono Nerd Font";
          };
          bold = {
            family = "JetBrainsMono Nerd Font";
          };
          italic = {
            family = "JetBrainsMono Nerd Font";
          };
        };
        keyboard.bindings = [
          {
            key = "Right";
            mods = "Control";
            chars = "\u001BF";
          }
          {
            key = "Left";
            mods = "Control";
            chars = "\u001BB";
          }
        ];
      };
    };
  };
}
