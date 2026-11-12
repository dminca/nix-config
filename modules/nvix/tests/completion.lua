-- Run with: nvim --headless -u NONE -l modules/nvix/tests/completion.lua
vim.opt.runtimepath:prepend("modules/nvix")

local blink, treesitter
local noop = function() end
for _, name in ipairs({
  "catppuccin", "Comment", "nvim-surround", "nvim-autopairs", "cord",
  "remote-nvim", "gx", "trim", "flash", "smart-splits", "nvim-web-devicons",
  "which-key", "harpoon", "bufferline", "windows", "colorizer", "dressing",
  "nvim-lastplace", "fidget", "noice", "diffview", "git-conflict", "gitsigns",
  "mini.ai", "nvim-treesitter.configs", "treesitter-context", "luasnip",
  "auto-session", "leetcode", "todo-comments", "neoscroll", "trouble",
  "tiny-inline-diagnostic", "lspsaga", "ufo", "lualine",
}) do
  package.preload[name] = function() return { setup = noop } end
end
package.preload["diffview.actions"] = function() return { toggle_files = noop } end
package.preload["blink.cmp"] = function()
  return { setup = function(config) blink = config end }
end
package.preload["nvim-treesitter.configs"] = function()
  return { setup = function(config) treesitter = config end }
end
package.preload.nvix = function() return { codesnap_available = false, guard = { writer = false } } end
vim.cmd.colorscheme = noop

require("nvix.editor.plugins").setup()
assert(not treesitter.auto_install, "concurrent readers must not install parsers")
require("nvix").guard.writer = true
require("nvix.editor.plugins").setup()
assert(treesitter.auto_install, "the writer must install missing parsers")
local mapping = blink.keymap["<C-space>"]
local accept = mapping[1]
assert(mapping[2] == "fallback")

local cmp = {
  snippet_active = function() return false end,
  accept = function() return "accepted" end,
  select_and_accept = function() return "snippet accepted" end,
}
assert(accept(cmp) == "accepted", "completion must work without Copilot")
cmp.snippet_active = function() return true end
assert(accept(cmp) == "snippet accepted", "active snippets must be accepted")

local called = false
package.preload.copilot = function() return {} end
package.preload["copilot.suggestion"] = function()
  return {
    is_visible = function() return true end,
    accept = function() called = true end,
  }
end
assert(accept(cmp) == true and called, "visible Copilot suggestions take precedence")
print("Completion mappings OK")
