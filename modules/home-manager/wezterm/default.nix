{
  lib,
  config,
  ...
}:
let
  cfg = config.profiles.common.wezterm;
  wordJumpBindings = ''
    {
      key = 'LeftArrow',
      mods = '${cfg.wordJumpMods}',
      action = wezterm.action.SendKey { key = 'LeftArrow', mods = 'CTRL' },
    },
    {
      key = 'RightArrow',
      mods = '${cfg.wordJumpMods}',
      action = wezterm.action.SendKey { key = 'RightArrow', mods = 'CTRL' },
    },
  '';
  hephaestusPaneBindings = ''
    {
      key = 'h',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.ActivatePaneDirection 'Left',
    },
    {
      key = 'j',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.ActivatePaneDirection 'Down',
    },
    {
      key = 'k',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.ActivatePaneDirection 'Up',
    },
    {
      key = 'l',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.ActivatePaneDirection 'Right',
    },
    {
      key = 'a',
      mods = 'SUPER|SHIFT',
      action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
    },
    {
      key = 's',
      mods = 'SUPER|SHIFT',
      action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
    },
  '';
in
{
  options.profiles.common.wezterm = {
    enable = lib.mkEnableOption "shared Home Manager WezTerm profile";

    style = lib.mkOption {
      type = lib.types.enum [
        "full"
        "word-jump-only"
      ];
      default = "full";
      description = "WezTerm profile style to apply.";
    };

    wordJumpMods = lib.mkOption {
      type = lib.types.enum [
        "OPT"
        "CTRL"
      ];
      default = "OPT";
      description = "Modifier for word-jump bindings in WezTerm.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.wezterm = {
      enable = true;
      extraConfig =
        if cfg.style == "full" then
          ''
            local wezterm = require 'wezterm'
            local config = wezterm.config_builder()
            local act = wezterm.action

            config.color_scheme = 'Catppuccin Mocha'
            config.font = wezterm.font('JetBrains Mono')
            config.font_size = 12
            config.window_decorations = 'RESIZE'
            config.unix_domains = {
              { name = 'unix' },
            }
            config.default_gui_startup_args = { 'connect', 'unix' }

            config.keys = {
              {
                key = 'd',
                mods = 'CMD|SHIFT',
                action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
              },
              {
                key = 'd',
                mods = 'CMD',
                action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
              },
              {
                key = 'w',
                mods = 'CMD',
                action = wezterm.action_callback(function(window, pane)
                  local domain = pane:get_domain_name()

                  if domain ~= 'local' then
                    window:perform_action(act.DetachDomain { DomainName = domain }, pane)
                  end

                  window:perform_action(act.QuitApplication, pane)
                end),
              },
              {
                key = '"',
                mods = 'CTRL|SHIFT|ALT',
                action = wezterm.action.Nop,
              },
              {
                key = '%',
                mods = 'CTRL|SHIFT|ALT',
                action = wezterm.action.Nop,
              },
              {
                key = 'h',
                mods = 'SUPER|SHIFT',
                action = wezterm.action.ActivatePaneDirection 'Left',
              },
              {
                key = 'j',
                mods = 'SUPER|SHIFT',
                action = wezterm.action.ActivatePaneDirection 'Down',
              },
              {
                key = 'k',
                mods = 'SUPER|SHIFT',
                action = wezterm.action.ActivatePaneDirection 'Up',
              },
              {
                key = 'l',
                mods = 'SUPER|SHIFT',
                action = wezterm.action.ActivatePaneDirection 'Right',
              },
              {
                key = 'UpArrow',
                mods = 'CTRL|SHIFT',
                action = wezterm.action.Nop,
              },
              {
                key = 'DownArrow',
                mods = 'CTRL|SHIFT',
                action = wezterm.action.Nop,
              },
              {
                key = 'LeftArrow',
                mods = 'CTRL|SHIFT',
                action = wezterm.action.Nop,
              },
              {
                key = 'RightArrow',
                mods = 'CTRL|SHIFT',
                action = wezterm.action.Nop,
              },
              ${wordJumpBindings}
            }

            return config
          ''
        else
          ''
            local wezterm = require 'wezterm'
            local config = wezterm.config_builder()

            config.keys = {
              ${wordJumpBindings}
              ${hephaestusPaneBindings}
            }

            return config
          '';
    };
  };
}
