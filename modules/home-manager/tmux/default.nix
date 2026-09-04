{
  config,
  lib,
  ...
}:
let
  cfg = config.profiles.common.tmux;
in
{
  options.profiles.common.tmux = {
    enable = lib.mkEnableOption "shared Home Manager tmux profile";
  };

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      clock24 = true;
      keyMode = "vi";
      prefix = "C-a";
      extraConfig = ''
        # Fix ctrl+left/right keys work right
        set-window-option -g xterm-keys on
        # tmux inception
        bind a send-prefix
        # yazi
        set -g allow-passthrough on
        set -ga update-environment TERM
        set -ga update-environment TERM_PROGRAM
        # Set 'v' for vertical and 'h' for horizontal split
        bind v split-window -h -c '#{pane_current_path}'
        bind b split-window -v -c '#{pane_current_path}'
        # vim-like pane switching
        bind -r k select-pane -U
        bind -r j select-pane -D
        bind -r h select-pane -L
        bind -r l select-pane -R
        # vim-like pane resizing
        bind -r C-k resize-pane -U
        bind -r C-j resize-pane -D
        bind -r C-h resize-pane -L
        bind -r C-l resize-pane -R
        # remove default binding since replacing
        unbind %
        unbind Up
        unbind Down
        unbind Left
        unbind Right
        unbind C-Up
        unbind C-Down
        unbind C-Left
        unbind C-Right
        #---------- BAR CONFIG
        set-option -g bell-action none
        set -g status-position bottom
        set -g status-justify left
        set -g status-bg colour235
        set -g status-fg green
        set -g status-right ' #(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD)    #{=50:pane_current_path}   %b %d %H:%M '
        set -g status-right-length 200
        set -g status-left '''
        set -sg escape-time 0

        set -g base-index 1
        setw -g pane-base-index 1
        set -g pane-border-format " #P: #{pane_current_command} "
      '';
      terminal = "tmux-256color";
      historyLimit = 5000;
      baseIndex = 1;
      secureSocket = true;
    };
  };
}
