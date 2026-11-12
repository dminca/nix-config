local M = {}

function M.setup()
  require("catppuccin").setup({
    flavour = "mocha", transparent_background = true, italic = true, bold = true,
    integrations = { native_lsp = { enabled = true, underlines = {
      errors = { "undercurl" }, hints = { "undercurl" },
      warnings = { "undercurl" }, information = { "undercurl" },
    } } },
  })
  vim.cmd.colorscheme("catppuccin")
  for _, name in ipairs({ "Error", "Warn", "Info", "Hint" }) do
    vim.api.nvim_set_hl(0, "DiagnosticUnderline" .. name, { undercurl = true })
  end
  vim.api.nvim_set_hl(0, "WhichKeyIcon", { link = "NONE", underline = false, undercurl = false })
  vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE", ctermbg = "NONE" })

  require("Comment").setup({ toggler = { line = "<leader>/" }, opleader = { line = "<leader>/" } })
  require("nvim-surround").setup()
  require("nvim-autopairs").setup()
  require("cord").setup()
  require("remote-nvim").setup()
  require("gx").setup()
  require("trim").setup()
  require("flash").setup({ modes = { char = { enabled = false } } })
  require("smart-splits").setup()
  require("nvim-web-devicons").setup()
  if require("nvix").codesnap_available ~= false then
    local codesnap_ok, codesnap_error = pcall(function()
      require("codesnap").setup({ snapshot_config = {
        background = { stops = { { color = "#00000000" }, { color = "#00000000" } } },
        theme = "vercel@https://raw.githubusercontent.com/Railly/one-hunter-vscode/refs/heads/main/themes/OneHunter-Vercel-color-theme.json",
        watermark = { content = "" },
      } })
    end)
    if not codesnap_ok then
      vim.notify("CodeSnap unavailable: " .. tostring(codesnap_error), vim.log.levels.WARN)
    end
  end
  require("which-key").setup({ preset = "helix", icons = { colors = false }, spec = {
    { "<leader>b", group = "buffers", icon = "" }, { "<leader><tab>", group = "tabs", icon = "" },
    { "<leader>q", group = "quit/session", icon = "" }, { "<leader>i", group = "insert" },
    { "<leader>v", group = "visual" }, { "<leader>u", group = "ui" },
    { "<leader>o", group = "open" }, { "<leader>d", group = "diff" },
    { "<leader>c", group = "quickfix" }, { "<leader>g", group = "git" },
    { "<leader>gh", group = "hunks" }, { "<leader>.", group = "scratch" },
    { "<leader>s", group = "search" }, { "<leader>f", group = "file/find" },
    { "<leader>p", group = "preview" }, { "<leader>R", group = "HTTP requests" },
  } })
  require("harpoon"):setup()
  require("bufferline").setup({ options = {
    diagnostics = "nvim_lsp", buffer_close_icon = "󰅙", close_icon = "󰅙",
    always_show_bufferline = true, hover = { enabled = true, delay = 200, reveal = { "close" } },
  } })
  require("windows").setup({ ignore = { filetype = { "snacks_picker_list", "snacks_layout_box" } } })
  require("colorizer").setup({ filetypes = { "*" }, user_default_options = {
    names = true, RRGGBBAA = true, AARRGGBB = true, rgb_fn = true,
    hsl_fn = true, css = true, css_fn = true, tailwind = true,
    mode = "virtualtext", virtualtext = "■", always_update = true,
  } })
  require("dressing").setup({ input = { mappings = { n = { q = "Close", k = "HistoryPrev", j = "HistoryNext" } } } })
  require("nvim-lastplace").setup()
  require("fidget").setup({ progress = { display = { progress_icon = { "moon" } } },
    notification = { window = { relative = "editor", winblend = 0, border = "none" } } })
  require("noice").setup({
    presets = { bottom_search = true },
    routes = {
      { filter = { event = "msg_show", kind = { "shell_out" } }, view = "notify", opts = { level = "info", title = "stdout" } },
      { filter = { event = "msg_show", kind = { "shell_err" } }, view = "notify", opts = { level = "error", title = "stderr" } },
    },
    views = { cmdline_popup = { position = { row = -2, col = "50%" }, border = { style = "none" } },
      cmdline_popupmenu = { position = { row = -5, col = "50%" } } },
    lsp = { override = { ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true, ["cmp.entry.get_documentation"] = true },
      hover = { enabled = false }, message = { enabled = false },
      signature = { enabled = false }, progress = { enabled = false } },
  })
  local toggle_files = require("diffview.actions").toggle_files
  require("diffview").setup({ file_panel = { win_config = { position = "right", width = 30 } },
    keymaps = { view = { { "n", "<leader>e", toggle_files, { desc = "Toggle the view of files panel" } } },
      file_panel = { { "n", "<leader>e", toggle_files, { desc = "Toggle the view of files panel" } } } } })
  require("git-conflict").setup({ default_mappings = true })
  require("gitsigns").setup({ current_line_blame = true, preview_config = { border = "rounded" },
    signs = { add = { text = "▏" }, change = { text = "▏" }, delete = { text = "▏" },
      topdelete = { text = "󰐊" }, changedelete = { text = "▎" } } })
  require("mini.ai").setup()
  local legacy, treesitter = pcall(require, "nvim-treesitter.configs")
  if legacy then
    local guard = require("nvix").guard
    local parser_directory = vim.fn.stdpath("data") .. "/treesitter"
    vim.fn.mkdir(parser_directory .. "/parser", "p")
    vim.opt.runtimepath:prepend(parser_directory)
    local group = vim.api.nvim_create_augroup("nvix_treesitter", { clear = true })
    local function install_parser()
      local parsers = require("nvim-treesitter.parsers")
      local lang = parsers.get_buf_lang()
      if lang and parsers.get_parser_configs()[lang] then
        -- Legacy auto_install can overlap builds in the same source directory.
        require("nvim-treesitter.install").ensure_installed_sync({ lang })
      end
    end
    if not guard or guard.writer then
      vim.api.nvim_create_autocmd("FileType", { group = group, callback = install_parser })
    end
    treesitter.setup({
      parser_install_dir = parser_directory,
      highlight = { enable = true }, indent = { enable = true },
      incremental_selection = { enable = true },
      auto_install = false,
    })
    if not guard or guard.writer then install_parser() end
  else
    require("nvim-treesitter").setup()
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("nvix_treesitter", { clear = true }),
      callback = function(args) pcall(vim.treesitter.start, args.buf) end,
    })
  end
  require("treesitter-context").setup({ max_lines = 4, min_window_height = 40 })
  require("luasnip").setup()
  require("blink.cmp").setup({
    fuzzy = { implementation = "lua" },
    completion = { menu = { border = "rounded" }, list = { selection = { preselect = false } } },
    keymap = {
      ["<C-j>"] = { "select_next", "fallback" }, ["<C-k>"] = { "select_prev", "fallback" },
      ["<C-l>"] = { "snippet_forward", "fallback" }, ["<C-h>"] = { "snippet_backward", "fallback" },
      ["<C-u>"] = { "scroll_documentation_up", "fallback" }, ["<C-d>"] = { "scroll_documentation_down", "fallback" },
      ["<C-space>"] = { function(cmp)
        local ok = pcall(require, "copilot")
        if ok then
          vim.g.copilot_no_tab_map, vim.g.copilot_assume_mapped, vim.g.copilot_tab_fallback = true, true, ""
          local suggestion = require("copilot.suggestion")
          if suggestion.is_visible() then
            suggestion.accept()
            return true
          end
        end
        if cmp.snippet_active() then return cmp.select_and_accept() end
        return cmp.accept()
      end, "fallback" },
    },
  })
  require("auto-session").setup({ use_git_branch = true,
    session_lens = { picker_opts = { preview = true }, mappings = { delete_session = { "n", "d" } } } })
  vim.g.firenvim_config = { globalSettings = { cmdline = "neovim", content = "text", priority = 0,
    selector = "textarea", takeover = "never" }, localSettings = { [".*"] = { takeover = "never", cmdline = "neovim" } } }
  require("leetcode").setup({ lang = "python3" })
  require("todo-comments").setup()
  require("neoscroll").setup()
  require("trouble").setup()
  require("tiny-inline-diagnostic").setup()
  require("lspsaga").setup({
    lightbulb = { enable = false, virtual_text = false }, outline = { keys = { jump = "<cr>" } },
    ui = { border = "rounded" }, scroll_preview = { scroll_down = "<c-d>", scroll_up = "<c-u>" },
  })
  require("ufo").setup({
    provider_selector = function() return { "lsp", "indent" } end,
    preview = { mappings = { close = "q", switch = "K" } },
  })
  require("lualine").setup({
    options = { theme = (function()
      local theme = {}
      for _, mode in ipairs({ "normal", "insert", "visual", "replace", "command", "inactive" }) do
        theme[mode] = { a = { fg = "none" }, c = { bg = "none" } }
      end
      return theme
    end)(), always_divide_middle = true, globalstatus = true, icons_enabled = true,
      component_separators = { left = "", right = "" }, section_separators = { left = "", right = "" },
      disabled_filetypes = { "Outline", "neo-tree", "dashboard", "snacks_dashboard", "snacks_terminal" } },
    sections = {
      lualine_a = { { "fileformat", color = "SLGreen", padding = { left = 1, right = 1 } } },
      lualine_b = { "encoding" },
      lualine_c = { { "b:gitsigns_head", icon = "", color = { gui = "bold" } },
        { "diff", source = function()
          local s = vim.b.gitsigns_status_dict
          if s then return { added = s.added, modified = s.changed, removed = s.removed } end
        end, symbols = { added = " ", modified = " ", removed = " " } },
        { "diagnostics", sources = { "nvim_diagnostic" },
          symbols = { error = " ", warn = " ", info = " ", hint = " " } } },
      lualine_x = { { function() return require("noice").api.status.mode.get() end,
        cond = function() return require("noice").api.status.mode.has() end, color = { fg = "#ff9e64" } },
        function()
          local clients, names = vim.lsp.get_clients(), {}
          if #clients == 0 then return "Ls Inactive" end
          for _, client in ipairs(clients) do
            if client.name ~= "copilot" and client.name ~= "null-ls" and client.name ~= "typos_lsp" then
              names[#names + 1] = client.name:gsub("%[%d+%]", "")
            end
          end
          for _, formatter in ipairs(require("conform").list_formatters()) do
            if formatter.available and formatter.name ~= "squeeze_blanks" and formatter.name ~= "trim_whitespace" and formatter.name ~= "trim_newlines" then
              names[#names + 1] = formatter.name
            end
          end
          return "[" .. table.concat(vim.fn.uniq(names), ", ") .. "]"
        end, "filetype" },
      lualine_y = { "progress" }, lualine_z = { "location", function()
        for _, client in ipairs(vim.lsp.get_clients()) do
          if client.name == "copilot" then return "%#SLGreen#" end
        end
        return ""
      end },
    },
  })
end

return M
