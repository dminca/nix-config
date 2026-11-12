-- Run with: nvim --headless -u NONE -l modules/nvix/tests/codesnap-reader.lua
vim.opt.runtimepath:prepend("modules/nvix")

if vim.env.NVIX_CODESNAP_READER_TEST == "1" then
  package.preload["nvix.plugins"] = function()
    return { { src = "https://example.invalid/codesnap.nvim" } }
  end
  for _, name in ipairs({ "nvix.mason", "nvix.lsp", "nvix.editor" }) do
    package.preload[name] = function() return { setup = function() end } end
  end
  require("nvix").setup()
  assert(require("nvix").guard and not require("nvix").guard.writer)
  assert(require("nvix").codesnap_available == false)
  assert(vim.fn.filereadable(vim.env.NVIX_CODESNAP_MARKER) == 0, "reader loaded CodeSnap")
  return
end

local root = vim.fn.tempname()
local state = root .. "/state/nvix"
local plugin = root .. "/data/nvim/site/pack/core/opt/codesnap.nvim"
vim.fn.mkdir(state, "p", 448)
vim.fn.mkdir(plugin .. "/plugin", "p", 448)
assert(vim.fn.writefile({ "call writefile(['loaded'], $NVIX_CODESNAP_MARKER)" },
  plugin .. "/plugin/codesnap.vim") == 0)
local function git(args)
  local result = vim.system(vim.list_extend({ "git", "-C", plugin }, args), { text = true }):wait()
  assert(result.code == 0, result.stderr)
end
git({ "init", "--quiet" })
git({ "remote", "add", "origin", "https://example.invalid/codesnap.nvim" })

local ffi = require("ffi")
ffi.cdef("int flock(int fd, int operation);")
local fd = assert(vim.uv.fs_open(state .. "/plugins.lock", "a+", 384))
assert(ffi.C.flock(fd, 1 + 4) == 0)
local result = vim.system({
  vim.v.progpath, "--headless", "-u", "NONE", "-l", "modules/nvix/tests/codesnap-reader.lua",
}, {
  text = true,
  timeout = 10000,
  env = {
    NVIX_CODESNAP_READER_TEST = "1",
    NVIX_CODESNAP_MARKER = root .. "/loaded",
    XDG_STATE_HOME = root .. "/state",
    XDG_CONFIG_HOME = root .. "/config",
    XDG_DATA_HOME = root .. "/data",
    XDG_CACHE_HOME = root .. "/cache",
  },
}):wait()
vim.uv.fs_close(fd)
vim.fn.delete(root, "rf")
assert(result.code == 0, result.stderr)
print("CodeSnap reader isolation OK")
