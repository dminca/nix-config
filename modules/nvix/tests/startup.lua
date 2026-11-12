-- Run with: nvim --headless -u NONE -l modules/nvix/tests/startup.lua
vim.opt.runtimepath:prepend("modules/nvix")

if vim.env.NVIX_STARTUP_TEST_CHILD == "1" then
  package.preload.nvix = function()
    return {
      setup = function()
        assert(vim.v.vim_did_init == 1, "bootstrap ran before the initial plugin scan")
        vim.g.nvix_test_started = true
        vim.api.nvim_create_autocmd("FileType", {
          callback = function() vim.g.nvix_test_filetype = true end,
        })
      end,
    }
  end
  require("nvix.startup")
  return
end

local file = vim.fn.tempname() .. ".lua"
local function check(path)
  local command = { vim.v.progpath, "--headless", "-u", "modules/nvix/tests/startup.lua" }
  if path then command[#command + 1] = path end
  command[#command + 1] = path
    and "+lua assert(vim.g.nvix_test_started and vim.g.nvix_test_filetype, 'startup missed filetype')"
    or "+lua assert(vim.g.nvix_test_started, 'startup missed VimEnter')"
  command[#command + 1] = "+qa!"
  local result = vim.system(command,
    { text = true, env = { NVIX_STARTUP_TEST_CHILD = "1" }, timeout = 10000 }):wait()
  assert(result.code == 0 and not (result.stderr or ""):find("Error", 1, true),
    "startup test failed: " .. (result.stderr or ""))
end
check(nil)
check(file)
assert(vim.fn.writefile({ "return true" }, file) == 0)
check(file)
vim.fn.delete(file)
print("Startup ordering OK")
