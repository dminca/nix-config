local M = {}

function M.setup()
  local keys = {
    ["<c-d>"] = { "preview_scroll_down", mode = "n" },
    ["<c-u>"] = { "preview_scroll_up", mode = "n" },
    ["-"] = { "edit_split", mode = "n" }, ["|"] = { "edit_vsplit", mode = "n" },
  }
  require("snacks").setup({
    bigfile = { enabled = true }, scroll = { enabled = false }, animate = { enabled = true },
    quickfile = { enabled = true }, indent = { enabled = true }, words = { enabled = true },
    statuscolumn = { enabled = true },
    image = { enabled = true, border = "none", doc = { conceal = true, inline = true } },
    notifier = { enabled = true, style = "minimal", top_down = false },
    styles = { ziggity = { width = 0, height = 0 } },
    dashboard = { enabled = true, sections = {
      { section = "header" },
      { pane = 2, section = "terminal", cmd = "colorscript -e square", height = 5, padding = 1 },
      { section = "keys", gap = 1, padding = 1 },
      { pane = 2, icon = " ", desc = "Browse Repo", padding = 1, key = "b", action = function() Snacks.gitbrowse() end },
      function()
        local in_git = Snacks.git.get_root() ~= nil
        local cmds = {
          { title = "Notifications", cmd = "gh api notifications -q '.[0:5][] | (.repository.full_name + \": \" + .subject.title)'",
            action = function() vim.ui.open("https://github.com/notifications") end, key = "n", icon = " ", height = 5, enabled = true },
          { title = "Open Issues", cmd = "PAGER= gh issue list -L 3", key = "i", icon = " ", height = 7,
            action = function() vim.fn.jobstart("gh issue list --web", { detach = true }) end },
          { title = "Open PRs", cmd = "PAGER= gh pr list -L 3", key = "P", icon = " ", height = 7,
            action = function() vim.fn.jobstart("gh pr list --web", { detach = true }) end },
          { title = "Git Status", cmd = "git --no-pager diff --stat -B -M -C", icon = " ", height = 10 },
        }
        return vim.tbl_map(function(cmd)
          return vim.tbl_extend("force", { pane = 2, section = "terminal", enabled = in_git,
            padding = 1, ttl = 300, indent = 3 }, cmd)
        end, cmds)
      end,
    } },
    picker = {
      enabled = true, layout = { preset = "ivy" }, layouts = { vscode = { layout = { width = 0.7 } } },
      actions = { pick_win = function(picker)
        if not picker.layout.split then picker.layout:hide() end
        local win = Snacks.picker.util.pick_win({ main = picker.main, float = false, filter = function(_, buf)
          local ft = vim.bo[buf].ft
          return ft == "snacks_dashboard" or not ft:find("^snacks")
        end })
        if not win then
          if not picker.layout.split then picker.layout:unhide() end
          return true
        end
        picker.main = win
        if not picker.layout.split then
          vim.defer_fn(function() if not picker.closed then picker.layout:unhide() end end, 100)
        end
      end },
      win = { input = { keys = keys }, list = { keys = vim.tbl_extend("force", keys, {
        ["<Enter>"] = { { "pick_win", "jump" }, mode = { "n", "i" } },
      }) } },
      sources = { explorer = {
        on_show = function(picker)
          local position, rel = picker.resolved_layout.layout.position, picker.layout.root
          local function update(win)
            local border = win:border_size().left + win:border_size().right
            win.opts.row = vim.api.nvim_win_get_position(rel.win)[1]
            win.opts.height = 0.8
            if position == "left" then
              win.opts.col = vim.api.nvim_win_get_width(rel.win) + 1
              win.opts.width = math.max(20, math.min(100, vim.o.columns - border - win.opts.col))
            elseif position == "right" then
              win.opts.col = -vim.api.nvim_win_get_width(rel.win) - 1
              win.opts.width = math.max(20, math.min(100, vim.o.columns - border + win.opts.col))
            end
            win:update()
          end
          local preview = Snacks.win.new({ relative = "editor", external = false, focusable = false,
            border = "rounded", backdrop = false, show = false,
            bo = { filetype = "snacks_float_preview", buftype = "nofile", buflisted = false, swapfile = false, undofile = false },
            on_win = function(win) update(win); picker:show_preview() end })
          rel:on("WinLeave", function()
            vim.schedule(function() if not picker:is_focused() then picker.preview.win:close() end end)
          end)
          rel:on("WinResized", function() update(preview) end)
          picker.preview.win, picker.main = preview, preview.win
        end,
        on_close = function(picker) picker.preview.win:close() end,
        layout = { preset = "sidebar", layout = { backdrop = false, width = 40, min_width = 40,
          height = 0, position = "right", border = "none", box = "vertical",
          { win = "list", border = "none" }, { win = "preview", title = "{preview}", height = 0.4, border = "top" },
        }, preview = false },
        actions = { toggle_preview = function(picker) picker.preview.win:toggle() end },
      } },
    },
  })
  vim.api.nvim_create_autocmd("VimEnter", { group = vim.api.nvim_create_augroup("nvix_snacks", { clear = true }), callback = function()
    _G.dd = function(...) Snacks.debug.inspect(...) end
    _G.bt = function() Snacks.debug.backtrace() end
    if vim.fn.has("nvim-0.11") == 1 then vim._print = function(_, ...) dd(...) end else vim.print = _G.dd end
    Snacks.toggle.diagnostics():map("<leader>ud")
    Snacks.toggle.line_number():map("<leader>ul")
    Snacks.toggle.inlay_hints():map("<leader>uh")
    Snacks.toggle.treesitter():map("<leader>uT")
    Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
    Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
    Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
    Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
    Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
  end })
end

return M
