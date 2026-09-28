{ config, ... }:
let
  inherit (config.nvix.mkKey) mkKeymap;
in
{
  # ziggity has no `Snacks.lazygit`-style bespoke integration (that module is
  # hardcoded to the `lazygit` binary/config format), so this opens it as a
  # plain floating terminal via `Snacks.terminal`. Editor integration (`e` in
  # ziggity reusing this Neovim instance) is configured once, globally, via
  # `ZIGGITY_CONFIG` in modules/home-manager/shell — not per-colorscheme like
  # lazygit's theme, since ziggity reads the terminal's own ANSI palette.
  #
  # No equivalent of `Snacks.lazygit.log_file()` / `.log()`: ziggity's CLI
  # only accepts --help/--version, no `-f <file>` or `log` args to filter the
  # view at launch time.
  plugins.snacks.settings.styles.ziggity = {
    width = 0;
    height = 0;
  };
  keymaps = [
    (mkKeymap "n" "<leader>gg" "<cmd>lua Snacks.terminal({ 'ziggity' }, { win = { style = 'ziggity' } })<cr>"
      "Ziggity"
    )
  ];
}
