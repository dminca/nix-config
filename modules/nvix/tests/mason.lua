-- Run with: nvim --headless -u NONE -l modules/nvix/tests/mason.lua
vim.opt.runtimepath:prepend("modules/nvix")
local mason = require("nvix.mason")

local core = mason.options({ profile = "core", system = "x86_64-linux", is_nixos = true })
assert(mason.selected("marksman", core))
assert(not mason.selected("texlab", core))
assert(not mason.unsupported("marksman", core))

core.servers.marksman = false
core.servers.texlab = { settings = {} }
assert(not mason.selected("marksman", core))
assert(mason.selected("texlab", core))
core.servers.texlab = false
assert(not mason.selected("texlab", core))

local bare = mason.options({ profile = "bare", servers = { marksman = true } })
assert(not mason.selected("marksman", bare))
local full = mason.options({ profile = "full", system = "aarch64-darwin" })
assert(mason.selected("texlab", full))
assert(not mason.unsupported("marksman", full))
full.system = "aarch64-linux"
assert(mason.unsupported("marksman", full))
assert(not pcall(mason.options, { profile = "invalid" }))
assert(not pcall(mason.options, { servers = { typo_server = true } }))

local runs, settings = 0
package.preload.mason = function() return { setup = function() end } end
package.preload["mason.settings"] = function() return { current = { install_root_dir = "/tmp" } } end
package.preload["mason-registry"] = function() return { on = function() end } end
package.preload["mason-tool-installer"] = function()
  return {
    setup = function(config) settings = config end,
    run_on_start = function() runs = runs + 1 end,
  }
end
assert(vim.v.vim_did_enter == 1, "Run this test after VimEnter")
mason.setup({ profile = "core" }, false)
assert(not settings.run_on_start and runs == 0, "A concurrent reader must not start Mason updates")
mason.setup({ profile = "core" }, true)
assert(settings.run_on_start and runs == 1, "A late writer must start Mason updates")
print("Mason profile selection OK")
