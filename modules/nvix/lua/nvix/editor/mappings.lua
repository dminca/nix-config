local M = {}

function M.setup()
  local function map(mode, lhs, rhs, desc, extra)
    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { silent = true, desc = desc }, extra or {}))
  end
  for _, item in ipairs({
    { "v", "<c-s>", "<esc>:w<cr>", "Saving File" }, { "v", "<c-c>", "<esc>", "Escape" },
    { "v", "<a-j>", ":m '>+1<cr>gv-gv", "Move Selected Line Down" },
    { "v", "<a-k>", ":m '<lt>-2<cr>gv-gv", "Move Selected Line Up" },
    { "v", "<", "<gv", "Indent out" }, { "v", ">", ">gv", "Indent in" },
    { "v", "<space>", "<Nop>", "Mapped to Nothing" },
    { "i", "jk", "<esc>", "Normal Mode" }, { "i", "<c-s>", "<esc>:w ++p<cr>", "Save file" },
    { "i", "<a-j>", "<esc>:m .+1<cr>==gi", "Move Line Down" },
    { "i", "<a-k>", "<esc>:m .-2<cr>==gi", "Move Line Up" },
    { "n", "<c-s>", "<cmd>w ++p<cr>", "Save the file" },
    { "n", "<a-+>", "<C-a>", "Increase Number" }, { "n", "<a-->", "<C-x>", "Decrease Number" },
    { "n", "<a-j>", "<cmd>m .+1<cr>==", "Move line Down" },
    { "n", "<a-k>", "<cmd>m .-2<cr>==", "Move line Up" },
    { "n", "<leader>qq", "<cmd>quitall!<cr>", "Quit!" },
    { "n", "<leader><leader>", "<cmd>nohl<cr>", "No highlight" },
    { "n", "<esc>", "<esc>:nohlsearch<cr>", "Escape" }, { "n", "<leader>A", "ggVG", "Select All" },
    { "n", "<leader>|", "<cmd>vsplit<cr>", "Vertical split" }, { "n", "<leader>-", "<cmd>split<cr>", "Horizontal split" },
    { "n", "<leader>cn", "<cmd>cnext<cr>", "Quickfix next" }, { "n", "<leader>cp", "<cmd>cprev<cr>", "Quickfix previous" },
    { "n", "<leader>cq", "<cmd>cclose<cr>", "Close quickfix" },
    { "n", "n", "nzzzv", "Move to center" }, { "n", "N", "Nzzzv", "Move to center" },
    { "n", "<leader>bp", "<cmd>BufferLinePick<cr>", "Buffer Line Pick" },
    { "n", "<leader>qc", "<cmd>bp | bd #<cr>", "Buffer close" },
    { "n", "<leader>bP", "<cmd>BufferLineTogglePin<cr>", "Buffer Pin" },
    { "n", "<leader>bd", "<cmd>BufferLineSortByDirectory<cr>", "Buffer Sort by dir" },
    { "n", "<leader>be", "<cmd>BufferLineSortByExtension<cr>", "Buffer Sort by ext" },
    { "n", "<leader>bt", "<cmd>BufferLineSortByTabs<cr>", "Buffer Sort by Tabs" },
    { "n", "<leader>bL", "<cmd>BufferLineCloseRight<cr>", "Close buffers right" },
    { "n", "<leader>bH", "<cmd>BufferLineCloseLeft<cr>", "Close buffers left" },
    { "n", "<leader>bc", "<cmd>BufferLineCloseOther<cr>", "Close other buffers" },
    { "n", "<a-s-h>", "<cmd>BufferLineMovePrev<cr>", "Move buffer left" },
    { "n", "<a-s-l>", "<cmd>BufferLineMoveNext<cr>", "Move buffer right" },
    { "n", "<s-h>", "<cmd>BufferLineCyclePrev<cr>", "Buffer Previous" },
    { "n", "<s-l>", "<cmd>BufferLineCycleNext<cr>", "Buffer Next" },
    { "n", "<leader><tab>j", "<cmd>tabn<cr>", "Next Tab" }, { "n", "<leader><tab>l", "<cmd>tabn<cr>", "Next Tab" },
    { "n", "<leader><tab>k", "<cmd>tabp<cr>", "Previous Tab" }, { "n", "<leader><tab>h", "<cmd>tabp<cr>", "Previous Tab" },
    { "n", "<leader>qt", "<cmd>tabclose<cr>", "Close Tab" }, { "n", "<leader><tab>q", "<cmd>tabclose<cr>", "Close Tab" },
    { "n", "<leader><tab>n", "<cmd>tab split<cr>", "Open buffer in new tab" },
    { "n", "<leader>ut", "<cmd>TrimToggle<cr>", "Toggle Trim" },
    { "v", "<leader>us", ":CodeSnap<cr>", "Snapshot selected code" },
    { "n", "<leader>gdd", "<cmd>DiffviewOpen<cr>", "Diffview" },
    { "n", "<leader>gdh", "<cmd>DiffviewFileHistory<cr>", "Diffview File History" },
    { "n", "<leader>gC", "<cmd>GitConflictListQf<cr>", "All GitConflicts to Quickfix" },
    { "n", "<leader>q.", "<cmd>AutoSession restore<cr>", "Last Session" },
    { "n", "<leader>ql", "<cmd>AutoSession search<cr>", "List Session" },
    { "n", "<leader>qd", "<cmd>AutoSession deletePicker<cr>", "Delete Session" },
    { "n", "<leader>qs", "<cmd>AutoSession save<cr>", "Save Session" },
    { "n", "<leader>qD", "<cmd>AutoSession purgeOrphaned<cr>", "Purge Orphaned Sessions" },
  }) do map(unpack(item)) end
  for _, mode in ipairs({ "n", "x" }) do
    for _, key in ipairs({ "j", "k" }) do
      map(mode, key, ('v:count || mode(1)[0:1] == "no" ? "%s" : "g%s"'):format(key, key),
        "Move " .. (key == "j" and "down" or "up"), { expr = true })
    end
  end
  for _, key in ipairs({ "x", "X", "c", "C" }) do
    map("n", key, '"_' .. key)
    map("v", key, '"_' .. ((key == "x" or key == "X") and "d" or "c"))
  end
  map("v", "p", '"_dP')
  map("c", "<C-j>", "<C-n>")
  map("c", "<C-k>", "<C-p>")
  for key, action in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
    map("n", "<c-a-" .. key .. ">", function() require("smart-splits")["resize_" .. action]() end, "Resize " .. action)
    map("n", "<c-" .. key .. ">", function() require("smart-splits")["move_cursor_" .. action]() end, "Move cursor " .. action)
  end
  map("n", "<c-\\>", function() require("smart-splits").move_cursor_previous() end, "Move Cursor Previous")
  map("n", "?", function() require("flash").jump({ forward = true, wrap = true, multi_window = true }) end, "Flash Search")
  map("n", "<leader>vt", function() require("flash").treesitter() end, "Select Treesitter Node")
  map("n", "<leader>dd", function()
    local diff = false
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do if vim.wo[win].diff then diff = true; break end end
    vim.cmd(diff and "windo diffoff" or "windo diffthis")
  end, "Toggle diff in open windows")
  map("n", "<leader>qw", function()
    if #vim.api.nvim_tabpage_list_wins(0) > 1 then
      local ok = pcall(vim.cmd.close)
      if ok then return end
    end
    vim.notify("Cannot close the last window!", vim.log.levels.WARN)
  end, "Close Window")
  map("n", "<leader>id", function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    vim.api.nvim_set_current_line(line:sub(1, col) .. "# " .. os.date("%d-%m-%y") .. line:sub(col + 1))
    if row < vim.api.nvim_buf_line_count(0) then vim.api.nvim_win_set_cursor(0, { row + 1, 0 }) end
  end, "Insert Date at cursor position")
  map("n", "<leader>uC", function() require("stay-centered").toggle() end, "Toggle stay-centered")
  map("n", "<leader>ft", function()
    vim.ui.input({ prompt = "Enter FileType: " }, function(input)
      if input and input ~= "" then vim.bo.filetype = input end
    end)
  end, "Set Filetype")
  map("n", "<leader>b.", function() require("harpoon"):list():add() end, "Add File to Harpoon")
  map("n", "<leader>bb", function()
    local harpoon = require("harpoon")
    harpoon.ui:toggle_quick_menu(harpoon:list())
  end, "Harpoon UI")

  for key, direction in pairs({ ["]h"] = "next", ["[h"] = "prev", ["]H"] = "last", ["[H"] = "first" }) do
    map("n", key, function()
      if vim.wo.diff and (direction == "next" or direction == "prev") then
        vim.cmd.normal({ direction == "next" and "]c" or "[c", bang = true })
      else require("gitsigns").nav_hunk(direction) end
    end, direction .. " Hunk")
  end
  for key, action in pairs({ gs = "stage_buffer", gr = "reset_buffer", gu = "undo_stage_hunk",
    gp = "preview_hunk_inline", gP = "preview_hunk", gK = "blame",
    gb = "toggle_current_line_blame", gw = "toggle_word_diff" }) do
    map("n", "<leader>" .. key, function() require("gitsigns")[action]() end, (action:gsub("_", " ")))
  end
  for key, action in pairs({ gs = "stage_hunk", gr = "reset_hunk", gp = "preview_hunk_inline" }) do
    map("v", "<leader>" .. key, function() require("gitsigns")[action]({ vim.fn.line("."), vim.fn.line("v") }) end, (action:gsub("_", " ")))
  end
  map("n", "<leader>gk", function() require("gitsigns").blame_line({ full = true }) end, "Blame Line")
  map("n", "<leader>ghH", function() require("gitsigns").setqflist() end, "Buffer Hunk to Quickfix")
  map("n", "<leader>ghh", function() require("gitsigns").setqflist("all") end, "All Hunks to Quickfix")
  map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select Hunk")

  for key, picker in pairs({
    sb = "lines", sB = "grep_buffers", sg = "grep", sw = "grep_word", ['s"'] = "registers",
    sa = "autocmds", sc = "command_history", sC = "commands", sd = "diagnostics",
    sD = "diagnostics_buffer", sH = "highlights", si = "icons", sj = "jumps",
    sl = "loclist", sm = "marks", sM = "man", sq = "qflist", sR = "resume",
    ss = "smart", st = "todo_comments", ["s:"] = "command_history", ["s,"] = "buffers",
    sh = "help", ff = "files", fF = "smart", ["f/"] = "grep", fr = "recent", fp = "projects",
    sS = "lsp_workspace_symbols",
  }) do map("n", "<leader>" .. key, function() Snacks.picker[picker]() end, (picker:gsub("_", " "))) end
  for key, picker in pairs({ gd = "lsp_definitions", gD = "lsp_declarations", gr = "lsp_references",
    gI = "lsp_implementations", gy = "lsp_type_definitions" }) do
    map("n", key, function() Snacks.picker[picker]() end, (picker:gsub("_", " ")))
  end
  map("x", "<leader>sw", function() Snacks.picker.grep_word() end, "Visual selection or word")
  map("n", "<leader>sP", function() Snacks.picker({ layout = "vscode" }) end, "Pickers")
  map("n", "<leader>sk", function() Snacks.picker.keymaps({ layout = "vscode" }) end, "Keymaps")
  map("n", "<leader>sT", function() Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end, "Todo")
  map("n", "<leader>su", function() Snacks.picker.undo({ win = { input = { keys = {
    y = { "yank_add", mode = "n" }, Y = { "yank_del", mode = "n" },
  } } } }) end, "Undo")
  map("n", "<leader>f?", function() Snacks.picker.grep({ args = { "--vimgrep", "--smart-case", "--fixed-strings" } }) end, "Grep")
  map("n", "<leader>..", function() Snacks.scratch() end, "Toggle Scratch Buffer")
  map("n", "<leader>.s", function() Snacks.scratch.select() end, "Select Scratch Buffer")
  map("n", "<leader>.r", function() Snacks.rename.rename_file() end, "Rename file")
  map("n", "<leader>sn", function() Snacks.notifier.show_history() end, "Notification History")
  map("n", "<leader>un", function() Snacks.notifier.hide() end, "Dismiss Notifications")
  map("n", "<leader>e", function() Snacks.explorer() end, "Explorer")
  map("n", "<leader>gg", function() Snacks.terminal({ "ziggity" }, { win = { style = "ziggity" } }) end, "Ziggity")

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("nvix_editor_lsp_mappings", { clear = true }),
    callback = function(args)
      local function lspmap(mode, lhs, rhs, desc)
        map(mode, lhs, rhs, desc, { buffer = args.buf })
      end
      for _, item in ipairs({
        { "<leader>lO", "<cmd>lua require('otter').activate()<cr>", "Force Otter" },
        { "<leader>la", "<cmd>Lspsaga code_action<cr>", "Code Action" },
        { "<leader>lo", "<cmd>Lspsaga outline<cr>", "Outline" },
        { "<leader>lw", "<cmd>Lspsaga show_workspace_diagnostics<cr>", "Workspace Diagnostics" },
        { "<leader>lr", "<cmd>Lspsaga rename ++project<cr>", "Rename" },
        { "gt", "<cmd>Lspsaga goto_type_definition<cr>", "Type Definitions" },
        { "<leader>l.", "<cmd>Lspsaga show_line_diagnostics<cr>", "Line Diagnostics" },
        { "gpd", "<cmd>Lspsaga peek_definition<cr>", "Peek Definition" },
        { "gpt", "<cmd>Lspsaga peek_type_definition<cr>", "Peek Type Definition" },
        { "[e", "<cmd>Lspsaga diagnostic_jump_prev<cr>", "Jump Prev Diagnostic" },
        { "]e", "<cmd>Lspsaga diagnostic_jump_next<cr>", "Jump Next Diagnostic" },
        { "<leader>lq", "<cmd>LspStop<cr>", "Stop LSP" },
        { "<leader>li", "<cmd>LspInfo<cr>", "LSP Info" },
        { "<leader>lR", "<cmd>LspRestart<cr>", "Restart LSP" },
        { "gr", "<cmd>Trouble lsp_references<cr>", "Trouble LSP References" },
        { "gd", "<cmd>Trouble lsp_definitions<cr>", "Trouble LSP Definitions" },
      }) do lspmap("n", unpack(item)) end
      lspmap("n", "K", function()
        if not require("ufo").peekFoldedLinesUnderCursor() then vim.cmd("Lspsaga hover_doc") end
      end, "Hover Doc")
      lspmap("n", "zR", function() require("ufo").openAllFolds() end, "Open all folds")
      lspmap("n", "zM", function() require("ufo").closeAllFolds() end, "Close all folds")
      lspmap("n", "zK", function()
        if not require("ufo").peekFoldedLinesUnderCursor() then vim.lsp.buf.hover() end
      end, "Peek Folded Lines")
      lspmap("n", "<C-s-k>", vim.lsp.buf.signature_help, "Signature Help")
      lspmap("n", "<leader>lD", function() Snacks.picker.lsp_definitions() end, "Definitions list")
      lspmap("n", "<leader>ls", function() Snacks.picker.lsp_symbols() end, "Symbols list")
      lspmap({ "n", "v" }, "<leader>lf", function() require("conform").format() end, "Format file")
      lspmap("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, "Previous Diagnostic")
      lspmap("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next Diagnostic")
      lspmap("n", "<leader>lk", function() vim.diagnostic.jump({ count = -1 }) end, "Previous Diagnostic")
      lspmap("n", "<leader>lj", function() vim.diagnostic.jump({ count = 1 }) end, "Next Diagnostic")
      lspmap("n", "<leader>lL", function()
        vim.diagnostic.enable(not vim.diagnostic.is_enabled())
      end, "Toggle Diagnostics")
      lspmap("n", "<leader>ll", function()
        local enabled = vim.diagnostic.config().virtual_text ~= false
        if enabled then
          vim.diagnostic.config({ virtual_text = false })
        else
          vim.diagnostic.config({ virtual_text = { source = "always" } })
        end
      end, "Toggle Virtual Text")
    end,
  })
end

return M
