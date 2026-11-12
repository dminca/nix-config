-- Run with: nvim --headless -u NONE -l modules/nvix/tests/update.lua
vim.opt.runtimepath:prepend("modules/nvix")

if vim.env.NVIX_UPDATE_TEST then
  local messages = {}
  vim.notify = function(message) messages[#messages + 1] = message end
  package.preload["nvix.plugins"] = function() return {} end
  for _, name in ipairs({ "nvix.mason", "nvix.lsp", "nvix.editor" }) do
    package.preload[name] = function() return { setup = function() end } end
  end
  vim.pack.add = function() end
  vim.pack.update = function()
    local directory = vim.fn.stdpath("log")
    vim.fn.mkdir(directory, "p")
    local section = vim.env.NVIX_UPDATE_TEST == "failure" and "# Error -------" or "# Update -------"
    assert(vim.fn.writefile({ "========== Update ==========", section, "" }, directory .. "/nvim-pack.log", "a") == 0)
  end
  require("nvix").setup()
  vim.wait(100)
  local warned = vim.iter(messages):any(function(message)
    return message:find("Plugin startup update failed", 1, true) ~= nil
  end)
  assert(warned == (vim.env.NVIX_UPDATE_TEST == "failure"), "incorrect update failure warning")
  return
end

local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")
for _, result in ipairs({ "failure", "success" }) do
  local process = vim.system({
    vim.v.progpath, "--headless", "-u", "NONE", "-l", "modules/nvix/tests/update.lua",
  }, {
    text = true,
    timeout = 10000,
    env = {
      NVIX_UPDATE_TEST = result,
      XDG_STATE_HOME = root .. "/state",
      XDG_CONFIG_HOME = root .. "/config",
      XDG_DATA_HOME = root .. "/data",
      XDG_CACHE_HOME = root .. "/cache",
    },
  }):wait()
  if process.code ~= 0 then
    vim.fn.delete(root, "rf")
    error("update test failed: " .. (process.stderr or ""))
  end
end
vim.fn.delete(root, "rf")
print("Plugin update reporting OK")
