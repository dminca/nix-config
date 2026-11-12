local M = {}

-- Upstream uses cmd functions for these servers to prefer project-local tools.
-- Use Mason's executable instead, retaining all other upstream defaults.
local commands = {
  biome = { "biome", "lsp-proxy" },
  cssls = { "vscode-css-language-server", "--stdio" },
  eslint = { "vscode-eslint-language-server", "--stdio" },
  html = { "vscode-html-language-server", "--stdio" },
  jsonls = { "vscode-json-language-server", "--stdio" },
  tailwindcss = { "tailwindcss-language-server", "--stdio" },
  ts_ls = { "typescript-language-server", "--stdio" },
  yamlls = { "yaml-language-server", "--stdio" },
}

local settings = {
  gopls = {
    settings = {
      gopls = {
        gofumpt = true,
        usePlaceholders = true,
        completeUnimported = true,
        semanticTokens = true,
        staticcheck = true,
      },
    },
  },
  lua_ls = {
    settings = { Lua = { diagnostics = { disable = { "miss-name" }, globals = { "vim", "cmp", "Snacks" } } } },
  },
  pyright = {
    settings = { pyright = { disableOrganizeImports = true }, python = { analysis = { ignore = { "*" } } } },
  },
  typos_lsp = { init_options = { diagnosticSeverity = "Hint" } },
  yamlls = {
    settings = {
      yaml = {
        format = { enable = true },
        validate = true,
        completion = true,
        hover = true,
        schemaStore = { enable = true, url = "https://www.schemastore.org/api/json/catalog.json" },
        kubernetesCRDStore = { enable = true },
        schemas = { kubernetes = "/*.yaml" },
      },
    },
  },
}

function M.setup(options)
  local mason = require("nvix.mason")
  local config = mason.options(vim.tbl_deep_extend("force", {}, mason.config or {}, options or {}))
  if config.profile == "bare" then
    return
  end
  vim.diagnostic.config({
    virtual_text = false,
    underline = true,
    severity_sort = true,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "",
        [vim.diagnostic.severity.WARN] = "",
        [vim.diagnostic.severity.INFO] = "",
        [vim.diagnostic.severity.HINT] = "",
      },
    },
    float = { border = config.border or "rounded", source = "always", focusable = false },
  })
  local capabilities = require("blink.cmp").get_lsp_capabilities()
  local rust_ready = false
  local rust_overrides = type(config.servers.rust_analyzer) == "table" and config.servers.rust_analyzer or {}
  -- Rustacean uses native vim.lsp.start while preserving :RustLsp and its handlers.
  -- Its ftplugin must not attach until the Mason executable has passed its probe.
  vim.g.rustaceanvim = vim.tbl_deep_extend("force", vim.g.rustaceanvim or {}, {
    server = vim.tbl_deep_extend("force", {
      auto_attach = function(bufnr)
        return rust_ready and vim.bo[bufnr].buftype == ""
      end,
      cmd = { mason.bin .. "rust-analyzer" },
      capabilities = capabilities,
      logfile = vim.fn.stdpath("log") .. "/rust-analyzer.log",
    }, rust_overrides, {
      auto_attach = function(bufnr)
        return rust_ready and vim.bo[bufnr].buftype == ""
      end,
    }),
  })
  local rust_config
  if mason.selected("rust_analyzer", config) then
    local ok, resolved = pcall(require, "rustaceanvim.config.internal")
    if ok then
      rust_config = resolved
      rust_config.server = vim.tbl_deep_extend("force", rust_config.server, vim.g.rustaceanvim.server)
    else
      mason.warn("rustaceanvim configuration unavailable: " .. tostring(resolved))
    end
  end
  local group = vim.api.nvim_create_augroup("nvix_lsp", { clear = true })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client:supports_method("textDocument/inlayHint", event.buf) then
        vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
      end
    end,
  })

  local enabled, probing, warned, failed, cleanup = {}, {}, {}, {}, {}
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      for _, stop in pairs(cleanup) do
        stop("Neovim is exiting")
      end
    end,
  })
  local function attach_rust()
    if not rust_ready then
      return
    end
    local ok, rust = pcall(require, "rustaceanvim.lsp")
    if not ok then
      mason.warn("rust_analyzer not started: rustaceanvim is unavailable: " .. tostring(rust))
      return
    end
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == "rust"
        and vim.bo[bufnr].buftype == ""
        and #vim.lsp.get_clients({ bufnr = bufnr, name = "rust-analyzer" }) == 0
      then
        rust.start(bufnr)
      end
    end
  end
  local function warn_once(name, reason)
    if warned[name] ~= reason then
      warned[name] = reason
      mason.warn(name .. " not started: " .. reason
        .. ". See :Mason, :MasonLog and :LspLog; :NvixLspRetry retries runtime checks. No Nix fallback.")
    end
  end
  local function activate(name)
    if enabled[name] or probing[name] or failed[name] then
      return
    end
    local server = vim.lsp.config[name]
    local command = server and server.cmd
    if type(command) ~= "table" or type(command[1]) ~= "string" then
      warn_once(name, "no executable command in the native nvim-lspconfig definition")
      return
    end
    -- Never pick up an old Nix-provided server from PATH while Mason is installing.
    command = vim.deepcopy(command)
    if not command[1]:find("/", 1, true) then
      command[1] = mason.bin .. command[1]
    end
    if vim.fn.executable(command[1]) ~= 1 then
      warn_once(name, command[1] .. " is missing; waiting for asynchronous Mason installation")
      return
    end
    local metadata = mason.servers[name]
    local runtime = vim.deepcopy(metadata.runtime or {})
    if metadata.requires and vim.tbl_contains(metadata.requires, "node") then
      runtime[#runtime + 1] = "node"
    end
    for _, executable in ipairs(runtime) do
      if vim.fn.executable(executable) ~= 1 then
        warn_once(name, "missing runtime " .. executable .. "; enter the project's development environment")
        return
      end
    end
    vim.lsp.config(name, { cmd = command })
    local function enable()
      warned[name] = nil
      if name == "rust_analyzer" then
        if not rust_config then
          failed[name] = true
          warn_once(name, "rustaceanvim is unavailable")
          return
        end
        rust_config.server.cmd = command
        enabled[name] = true
        rust_ready = true
        attach_rust()
        return
      end
      enabled[name] = true
      -- enable() also activates matching buffers already open before installation.
      vim.lsp.enable(name)
    end
    if not config.is_nixos then
      enable()
      return
    end
    -- Probe the actual LSP command: gopls/cue/tofu have differing version
    -- subcommands, and several Node servers do not implement --version at all.
    probing[name] = true
    local rpc, timer, finished
    local function finish(reason)
      if finished then
        return
      end
      finished = true
      cleanup[name] = nil
      if timer and not timer:is_closing() then
        timer:stop()
        timer:close()
      end
      if rpc then
        rpc.terminate()
      end
      vim.schedule(function()
        probing[name] = nil
        if vim.v.exiting ~= vim.NIL then
          return
        end
        if reason then
          failed[name] = true
          warn_once(name, reason)
          return
        end
        enable()
      end)
    end
    cleanup[name] = finish
    local ok, err = pcall(function()
      rpc = vim.lsp.rpc.start(command, {
        notification = function() end,
        on_exit = function(code, signal)
          finish("runtime probe exited before initialize (exit " .. code .. ", signal " .. signal .. ")")
        end,
        on_error = function(code, detail)
          finish("runtime probe failed: " .. tostring(code) .. ": " .. vim.inspect(detail))
        end,
      }, { cwd = vim.fn.getcwd(), detached = false })
      timer = vim.defer_fn(function()
        finish("runtime probe timed out waiting for an LSP initialize response")
      end, 30000)
      local sent = rpc.request("initialize", {
        processId = vim.fn.getpid(),
        rootUri = vim.uri_from_fname(vim.fn.getcwd()),
        capabilities = capabilities,
        initializationOptions = server.init_options,
        workspaceFolders = vim.NIL,
      }, function(init_error)
        -- Even a protocol error proves the executable and its runtime can run.
        -- Real project initialization is left to the regular client.
        if init_error then
          mason.warn(name .. " runtime is executable, but initialize probe returned: " .. vim.inspect(init_error))
        end
        finish()
      end)
      if not sent then
        finish("runtime probe could not send initialize")
      end
    end)
    if not ok then
      finish("cannot execute " .. command[1] .. ": " .. tostring(err))
    end
  end

  local selected = {}
  for _, name in ipairs(vim.tbl_keys(mason.servers)) do
    if mason.selected(name, config) and not mason.unsupported(name, config) then
      local overrides = config.servers[name]
      vim.lsp.config(name, vim.tbl_deep_extend("force", {
        capabilities = capabilities,
        cmd = commands[name],
      }, settings[name] or {}, type(overrides) == "table" and overrides or {}))
      selected[#selected + 1] = name
    end
  end
  local function refresh()
    for _, name in ipairs(selected) do
      activate(name)
    end
  end
  local function retry()
    failed = {}
    refresh()
  end
  vim.api.nvim_create_user_command("NvixLspRetry", retry, {
    force = true,
    desc = "Retry unavailable Mason LSP executables after changing the runtime environment",
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "MasonToolsUpdateCompleted",
    callback = retry,
  })
  -- Per-package success handles installs made manually from :Mason, too.
  require("mason-registry"):on("package:install:success", vim.schedule_wrap(retry))
  vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
    group = group,
    callback = function()
      refresh()
      attach_rust()
    end,
  })
  refresh()
end

return M
