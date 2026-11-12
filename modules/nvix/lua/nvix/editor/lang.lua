local M = {}

function M.setup()
  require("conform").setup({
    default_format_opts = { lsp_format = "prefer" },
    formatters_by_ft = {
      ["_"] = { "squeeze_blanks", "trim_whitespace", "trim_newlines" },
      xml = { "xmllint" }, yaml = { "yamlfix" }, json = { "fixjson" }, go = { "goimports" },
      lua = { "stylua" }, nix = { "nixfmt" }, terraform = { "tofu_fmt" },
      bash = { "shellcheck", "shellharden", "shfmt" }, sh = { "shellcheck", "shellharden", "shfmt" },
      zsh = { "shellcheck", "shellharden", "shfmt" }, toml = { "taplo" }, typst = { "typstyle" },
    },
    formatters = {
      squeeze_blanks = { command = "cat" },
      tofu_fmt = { command = "tofu", args = { "fmt", "-" }, stdin = true },
      taplo = { command = "taplo", args = { "format", "-" }, stdin = true },
    },
  })
  local group = vim.api.nvim_create_augroup("nvix_editor_language", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePre", { group = group, pattern = "*.go",
    callback = function() require("conform").format({ async = false }) end })
  -- markdown-preview's browserfunc is a Vim function, not an Ex command.
  vim.cmd([[function! MkdpNoOp(url)
endfunction]])
  vim.g.mkdp_echo_preview_url = 1
  vim.g.mkdp_open_to_the_world = 1
  vim.g.mkdp_browserfunc = "MkdpNoOp"
  require("img-clip").setup()
  require("render-markdown").setup({
    ignore = function(buf)
      buf = buf or 0
      return vim.api.nvim_buf_get_name(buf):match("/leetcode/") ~= nil or vim.bo[buf].filetype == "leetcode.nvim"
    end,
    link = { wiki = { body = function(ctx)
      if ((ctx and ctx.text) or ""):match("^[%d%s,%-%[%]%.\"']+$") then return false end
    end } },
  })
  require("glow").setup()
  require("typst-preview").setup({
    dependencies_bin = {
      tinymist = vim.fn.stdpath("data") .. "/mason/bin/tinymist",
      websocat = "websocat",
    },
  })
  require("crates").setup()
  require("nvim-ts-autotag").setup()
  require("ts-comments").setup()
  vim.api.nvim_create_autocmd("FileType", { group = group, pattern = { "http", "rest" },
    once = true, callback = function()
      require("kulala").setup({ global_keymaps = true, global_keymaps_prefix = "<leader>R", kulala_keymaps_prefix = "" })
    end })
  vim.api.nvim_create_autocmd("FileType", { group = group, pattern = "markdown", callback = function(args)
    vim.keymap.set("n", "<leader>pg", "<cmd>Glow<CR>", { buffer = args.buf, desc = "Markdown Glow preview" })
    vim.keymap.set("n", "<leader>pb", function()
      vim.cmd.MarkdownPreview()
      vim.defer_fn(function()
        local messages = vim.api.nvim_exec2("messages", { output = true }).output
        local url
        for line in messages:gmatch("[^\n]+") do
          local found = line:match("https?://[%w%.%-]+:%d+/%S*") or line:match("https?://[%w%.%-]+:%d+")
          if found then url = found end
        end
        if url then
          url = url:gsub("https?://[%w%.%-]+", "http://localhost")
          vim.fn.setreg("+", url)
          vim.notify("URL copied to clipboard: " .. url, vim.log.levels.INFO)
        else
          vim.notify("Markdown Preview URL not found in messages", vim.log.levels.WARN)
        end
      end, 500)
    end, { buffer = args.buf, desc = "Markdown Browser Preview + Copy URL" })
    vim.keymap.set("n", "<leader>pp", function() require("md-pdf").convert_md_to_pdf() end,
      { buffer = args.buf, desc = "Markdown Print PDF" })
  end })
  vim.keymap.set("n", "<leader>o<cr>", function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line, offset = vim.api.nvim_get_current_line(), 1
    while true do
      local first, last = line:find("[A-Za-z0-9_/%-]+", offset)
      if not first then return end
      if col + 1 >= first and col + 1 <= last then
        vim.api.nvim_win_set_cursor(0, { row, first - 1 })
        vim.cmd("normal! v")
        vim.api.nvim_win_set_cursor(0, { row, last })
        return
      end
      offset = last + 1
    end
  end, { desc = "Make note from text under cursor", silent = true })
end

return M
