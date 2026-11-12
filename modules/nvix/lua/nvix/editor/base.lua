local M = {}

function M.setup()
  vim.g.mapleader = " "
  vim.g.floating_window_options = { border = "rounded" }
  local opts = {
    clipboard = "unnamedplus", cursorline = true, cursorlineopt = "number",
    pumblend = 0, pumheight = 10, expandtab = true, shiftwidth = 2,
    smartindent = true, tabstop = 2, softtabstop = 2, ignorecase = true,
    smartcase = true, mouse = "a", cmdheight = 0, number = true,
    relativenumber = true, numberwidth = 2, ruler = false, signcolumn = "yes",
    splitbelow = true, splitright = true, splitkeep = "screen", termguicolors = true,
    conceallevel = 2, undofile = true, wrap = false, virtualedit = "block",
    winminwidth = 10, winwidth = 10, equalalways = false, fileencoding = "utf-8",
    list = true, smoothscroll = true, autoread = true, autowrite = true,
    swapfile = false, fillchars = { eob = " " }, updatetime = 500,
    timeout = true, timeoutlen = 250, foldcolumn = "1", foldlevel = 99,
    foldlevelstart = 99, foldenable = true,
  }
  for key, value in pairs(opts) do vim.opt[key] = value end
  vim.opt.whichwrap:append("<>[]hl")
  vim.opt.listchars:append("space:·")

  if vim.env.SSH_TTY then
    local osc52 = require("vim.ui.clipboard.osc52")
    local function paste() return vim.split(vim.fn.getreg('"'), "\n") end
    vim.g.clipboard = {
      name = "OSC 52",
      copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
      paste = { ["+"] = paste, ["*"] = paste },
    }
  end

  local group = vim.api.nvim_create_augroup("nvix_editor", { clear = true })
  local function autocmd(event, options)
    options.group = group
    vim.api.nvim_create_autocmd(event, options)
  end
  autocmd("TextYankPost", { callback = function() vim.highlight.on_yank() end })
  autocmd("FocusGained", { callback = function()
    if vim.fn.getcmdwintype() == "" then vim.cmd.checktime() end
  end })
  local watchers = {}
  autocmd({ "BufRead", "BufWritePost" }, { callback = function(args)
    local buf, path = args.buf, vim.api.nvim_buf_get_name(args.buf)
    if path == "" or vim.bo[buf].buftype ~= "" then return end
    if watchers[buf] then watchers[buf]:stop(); watchers[buf]:close() end
    local watcher = vim.uv.new_fs_event()
    if not watcher then return end
    local ok = watcher:start(path, {}, function(err)
      if err then return end
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) and not vim.bo[buf].modified then
          vim.api.nvim_buf_call(buf, function() vim.cmd.checktime() end)
        end
      end)
    end)
    if not ok then watcher:close(); watchers[buf] = nil; return end
    watchers[buf] = watcher
  end })
  autocmd("BufDelete", { callback = function(args)
    local watcher = watchers[args.buf]
    if watcher then watcher:stop(); watcher:close(); watchers[args.buf] = nil end
  end })
  autocmd({ "CursorMovedI", "InsertLeave" }, { callback = function()
    if vim.fn.pumvisible() == 0 and not vim.wo.previewwindow and vim.fn.getcmdwintype() == "" then
      vim.cmd.pclose()
    end
  end })
end

return M
