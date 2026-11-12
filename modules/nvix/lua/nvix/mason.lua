local M = {}

-- Native LSP names and Mason registry names are deliberately kept separate.
M.servers = {
  bashls = { package = "bash-language-server", requires = { "node", "npm" } },
  biome = { package = "biome", requires = { "node", "npm" } },
  cssls = { package = "css-lsp", requires = { "node", "npm" } },
  cue = { package = "cue", requires = { "go" } },
  emmet_ls = { package = "emmet-ls", requires = { "node", "npm" } },
  eslint = { package = "eslint-lsp", requires = { "node", "npm" } },
  gopls = { package = "gopls", requires = { "go" }, runtime = { "go" } },
  hls = { package = "haskell-language-server", requires = { "ghcup" }, runtime = { "ghc" } },
  html = { package = "html-lsp", requires = { "node", "npm" } },
  jsonls = { package = "json-lsp", requires = { "node", "npm" } },
  lua_ls = { package = "lua-language-server" },
  markdown_oxide = { package = "markdown-oxide" },
  marksman = { package = "marksman" },
  nil_ls = { package = "nil", requires = { "cargo", "rustc", "cc" } },
  pyright = { package = "pyright", requires = { "node", "npm" } },
  ruff = { package = "ruff", musl = true },
  rust_analyzer = { package = "rust-analyzer", musl = true, runtime = { "cargo", "rustc" } },
  svelte = { package = "svelte-language-server", requires = { "node", "npm" } },
  tailwindcss = { package = "tailwindcss-language-server", requires = { "node", "npm" } },
  taplo = { package = "taplo" },
  texlab = { package = "texlab", profile = "full", musl = true },
  tinymist = { package = "tinymist", musl = true },
  tofu_ls = { package = "tofu-ls" },
  ts_ls = { package = "typescript-language-server", requires = { "node", "npm" } },
  typos_lsp = { package = "typos-lsp", nixos_target = "linux_x64" },
  yamlls = { package = "yaml-language-server", requires = { "node", "npm" } },
}

function M.warn(message)
  vim.schedule(function()
    vim.notify(message, vim.log.levels.WARN, { title = "nvix LSP / Mason" })
  end)
end

-- Pass the same options to both setup functions, or set vim.g.nvix beforehand.
-- servers[name] = false disables a server; true or a table enables it.
-- A table also supplies native vim.lsp overrides.
function M.options(options)
  local config = vim.tbl_deep_extend("force", {}, vim.g.nvix or {}, options or {})
  config.profile = config.profile or config.package or "core"
  local host = vim.uv.os_uname()
  local arch = (host.machine == "arm64" or host.machine == "aarch64") and "aarch64" or host.machine
  config.system = config.system or (arch .. (host.sysname == "Darwin" and "-darwin" or "-linux"))
  if config.is_nixos == nil then
    config.is_nixos = vim.fn.filereadable("/etc/NIXOS") == 1
  end
  config.servers = config.servers or {}
  assert(vim.tbl_contains({ "bare", "core", "full" }, config.profile), "Invalid nvix profile")
  for name in pairs(config.servers) do
    assert(M.servers[name], "Unknown nvix server: " .. name)
  end
  return config
end

function M.selected(name, config)
  local server = M.servers[name]
  local override = config.servers[name]
  return config.profile ~= "bare"
    and override ~= false
    and (server.profile ~= "full" or config.profile == "full" or override ~= nil)
end

function M.unsupported(name, config)
  if config.system ~= "aarch64-darwin" and config.system ~= "x86_64-linux" then
    return "unsupported host " .. config.system
  end
end

function M.setup(options, update_on_start)
  M.config = M.options(options)
  if M.config.profile == "bare" then
    return
  end
  require("mason").setup({ PATH = "prepend" })
  M.bin = require("mason.settings").current.install_root_dir .. "/bin/"
  local registry = require("mason-registry")
  registry:on("package:install:failed", function(package, err)
    M.warn(package.name .. " installation/update failed: " .. tostring(err) .. ". See :MasonLog; no Nix fallback.")
  end)
  registry:on("update:failed", function()
    M.warn("Mason registry refresh failed. See :MasonLog; server installation will be retried next startup.")
  end)

  local tools = {}
  for _, name in ipairs(vim.tbl_keys(M.servers)) do
    if M.selected(name, M.config) then
      local server = M.servers[name]
      local reason = M.unsupported(name, M.config)
      if reason then
        M.warn(name .. " skipped: " .. reason .. ". No Nix fallback.")
      else
        local entry = { server.package }
        if M.config.is_nixos then
          entry.target = server.nixos_target or (server.musl and "linux_x64_musl" or nil)
        end
        entry.condition = function()
          for _, executable in ipairs(server.requires or {}) do
            if vim.fn.executable(executable) ~= 1 then
              M.warn(server.package .. " installation/update skipped: missing " .. executable .. ". No Nix fallback.")
              return false
            end
          end
          return true
        end
        tools[#tools + 1] = entry
      end
    end
  end
  if M.config.profile ~= "bare" then
    -- statix is a CLI linter, not a JSON-RPC server, despite the old Nixvim entry.
    tools[#tools + 1] = {
      "statix",
      condition = function()
        for _, executable in ipairs({ "cargo", "rustc", "cc" }) do
          if vim.fn.executable(executable) ~= 1 then
            M.warn("statix installation/update skipped: missing " .. executable)
            return false
          end
        end
        return true
      end,
    }
    M.warn("statix is a CLI linter, not an LSP (no JSON-RPC). Mason manages its installation; lint execution is not configured.")
  end
  table.sort(tools, function(a, b)
    return (type(a) == "table" and a[1] or a) < (type(b) == "table" and b[1] or b)
  end)
  local installer = require("mason-tool-installer")
  if update_on_start == false then
    M.warn("Mason startup installation/updates skipped: another managed Neovim instance is running.")
  end
  installer.setup({
    ensure_installed = tools,
    auto_update = true,
    run_on_start = update_on_start ~= false,
    start_delay = 1000,
    integrations = {
      ["mason-lspconfig"] = false,
      ["mason-null-ls"] = false,
      ["mason-nvim-dap"] = false,
    },
  })
  -- vim.pack may load the plugin after VimEnter, so its startup autocmd can miss it.
  if update_on_start ~= false and vim.v.vim_did_enter == 1 then
    installer.run_on_start()
  end
end

return M
