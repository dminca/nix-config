{
  ...
}:
{
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()

      config.color_scheme = 'Catppuccin Mocha'
      config.font = wezterm.font('JetBrains Mono')
      config.font_size = 12
      config.window_decorations = 'RESIZE'

      -- Custom key bindings for splits
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
        -- Unbind default split shortcuts
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
        -- Vim-like pane navigation (SUPER+SHIFT+hjkl)
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
        -- Unbind default pane direction shortcuts
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
        -- Word jump with Option+Arrow keys (macOS Terminal.app style)
        {
          key = 'LeftArrow',
          mods = 'OPT',
          action = wezterm.action.SendKey {
            key = 'b',
            mods = 'ALT',
          },
        },
        {
          key = 'RightArrow',
          mods = 'OPT',
          action = wezterm.action.SendKey {
            key = 'f',
            mods = 'ALT',
          },
        },
      }

      return config
    '';
  };
}
