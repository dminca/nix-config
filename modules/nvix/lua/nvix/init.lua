local M = {}
local uv = vim.uv

local function warn(message)
  vim.schedule(function()
    vim.notify(message, vim.log.levels.WARN, { title = "nvix bootstrap" })
  end)
end

local function plugin_name(spec)
  return spec.name or spec.src:gsub("/+$", ""):match("([^/]+)$"):gsub("%.git$", "")
end

local function markdown_build(path)
  if vim.fn.executable("bash") ~= 1 then
    error("markdown-preview build requires bash")
  end
  local metadata = vim.json.decode(table.concat(vim.fn.readfile(path .. "/package.json"), "\n"))
  local result = vim.system({ "bash", "install.sh", "v" .. metadata.version }, {
    cwd = path .. "/app",
    text = true,
    timeout = 120000,
  }):wait()
  if result.code ~= 0 then
    error("markdown-preview install failed: " .. (result.stderr or "") .. (result.stdout or ""))
  end
  local host = uv.os_uname()
  local platform = host.sysname == "Darwin"
    and (host.machine == "arm64" and "macos-arm64" or "macos")
    or "linux"
  local binary = path .. "/app/bin/markdown-preview-" .. platform
  if vim.fn.executable(binary) ~= 1 then
    error("markdown-preview installer did not produce " .. binary)
  end
  local probe = vim.system({ binary, "--version" }, { text = true, timeout = 10000 }):wait()
  if probe.code ~= 0 then
    error("markdown-preview binary cannot run on this host: " .. (probe.stderr or ""))
  end
end

local function update_plugins(names)
  local log = vim.fn.stdpath("log") .. "/nvim-pack.log"
  local before = uv.fs_stat(log)
  local offset = before and before.size or 0
  local updated, err = pcall(vim.pack.update, names, { force = true })
  if not updated then
    warn("Plugin startup update failed: " .. tostring(err))
    return
  end
  -- Forced updates report individual fetch failures only in nvim-pack.log.
  local after = uv.fs_stat(log)
  if not after or after.size < offset then
    warn("Could not inspect plugin update results in " .. log)
    return
  end
  local fd, open_error = uv.fs_open(log, "r", 0)
  if not fd then
    warn("Could not read plugin update log: " .. tostring(open_error))
    return
  end
  local text, read_error = uv.fs_read(fd, after.size - offset, offset)
  uv.fs_close(fd)
  if not text then
    warn("Could not read plugin update log: " .. tostring(read_error))
  elseif text:find("\n# Error ", 1, true) then
    warn("Plugin startup update failed for one or more plugins; see " .. log)
  end
end

-- A kernel advisory lock is both atomic and crash-recoverable. The same file
-- becomes a shared lifetime lease after startup; no PID files or stale TTLs.
local function lease()
  local ok, ffi = pcall(require, "ffi")
  if not ok then
    error("LuaJIT FFI is required for safe package locking; refusing an unlocked bootstrap")
  end
  pcall(ffi.cdef, "int flock(int fd, int operation);")
  local state = vim.env.XDG_STATE_HOME
  if not state or state == "" then
    state = vim.env.HOME .. "/.local/state"
  end
  local directory = state .. "/nvix"
  vim.fn.mkdir(directory, "p", 448)
  local info = uv.fs_lstat(directory)
  if not info or info.type ~= "directory" or info.uid ~= uv.getuid()
    or bit.band(info.mode, 18) ~= 0
  then
    error("Unsafe nvix lock directory: " .. directory)
  end
  local path = directory .. "/plugins.lock"
  info = uv.fs_lstat(path)
  if info and (info.type ~= "file" or info.uid ~= uv.getuid()) then
    error("Unsafe nvix lock file: " .. path)
  end
  local fd = assert(uv.fs_open(path, "a+", 384))
  local held = true
  local function close()
    if held then
      held = false
      -- Never unlink the inode: another instance may already have it open.
      uv.fs_close(fd)
    end
  end
  local function lock(operation)
    local success, result = pcall(function()
      return ffi.C.flock(fd, operation)
    end)
    if not success then
      close()
      error("flock is unavailable; refusing an unlocked bootstrap: " .. tostring(result))
    end
    return result == 0
  end
  local writer = lock(2 + 4) -- LOCK_EX | LOCK_NB
  if not writer and not lock(1 + 4) then -- LOCK_SH | LOCK_NB
    close()
    return nil, "another nvix instance is changing packages; startup skipped to avoid reading partial updates"
  end
  return {
    writer = writer,
    close = close,
    share = function()
      if not lock(1 + 4) then
        error("Unable to retain nvix's shared lifetime lease")
      end
    end,
  }
end

function M.setup(options)
  if M.started then
    return
  end
  vim.g.nvix = vim.tbl_deep_extend("force", {}, vim.g.nvix or {}, options or {})
  if not vim.pack or vim.fn.has("nvim-0.12") ~= 1 then
    warn("Neovim 0.12+ with vim.pack is required; native startup skipped (no Nixvim fallback).")
    return
  end
  local ok, guard, reason = pcall(lease)
  if not ok or not guard then
    warn(not ok and tostring(guard) or reason)
    return
  end
  M.started = true
  M.guard = guard
  local group = vim.api.nvim_create_augroup("nvix_bootstrap", { clear = true })
  vim.api.nvim_create_autocmd("VimLeave", {
    group = group,
    once = true,
    callback = guard.close,
  })

  local terminal_prompt, credential_interactive = vim.env.GIT_TERMINAL_PROMPT, vim.env.GCM_INTERACTIVE
  vim.env.GIT_TERMINAL_PROMPT = "0"
  vim.env.GCM_INTERACTIVE = "Never"
  local success, err = xpcall(function()
    local specs = require("nvix.plugins")
    local directory = vim.fn.stdpath("data") .. "/site/pack/core/opt/"
    vim.opt.packpath:prepend(vim.fn.stdpath("data") .. "/site")
    local names, paths = {}, {}
    for _, spec in ipairs(specs) do
      local name = plugin_name(spec)
      names[#names + 1] = name
      paths[name] = directory .. name
    end
    if guard.writer then
      vim.api.nvim_create_autocmd("PackChanged", {
        group = group,
        callback = function(event)
          local data = event.data
          if data.kind ~= "install" and data.kind ~= "update" then
            return
          end
          if data.spec.name == "markdown-preview.nvim" then
            local built, build_error = pcall(markdown_build, data.path)
            if not built then
              warn(tostring(build_error))
            end
          elseif data.spec.name == "firenvim" then
            warn("Firenvim plugin is available; browser/native-host installation is deliberately not automatic.")
          end
        end,
      })
      -- Install and update before loading plugin code. Both APIs finish their
      -- mutations before returning; build hooks above are synchronous as well.
      vim.pack.add(specs, {
        confirm = false,
        -- packadd! would mark the package loaded and prevent the later
        -- explicit packadd from sourcing scripts when bootstrap runs late.
        load = function(plugin)
          vim.opt.runtimepath:append(plugin.path)
        end,
      })
      update_plugins(names)
      vim.api.nvim_clear_autocmds({ group = group, event = "PackChanged" })
    else
      -- Even add() can install, replace a source, or rewrite the lockfile.
      -- Readers only packadd repositories that are already present.
      warn("Plugin installation/updates skipped: another managed Neovim instance is running.")
    end
    local missing = {}
    for name, path in pairs(paths) do
      if not uv.fs_stat(path .. "/.git") then
        missing[#missing + 1] = name
      end
    end
    if #missing > 0 then
      table.sort(missing)
      error("Required plugins unavailable: " .. table.concat(missing, ", ") .. ". No plugin fallback.")
    end
    if not guard.writer then
      for _, spec in ipairs(specs) do
        local path = paths[plugin_name(spec)]
        local remote = vim.system({ "git", "-C", path, "config", "--get", "remote.origin.url" }, {
          text = true,
          timeout = 10000,
        }):wait()
        local function normalize(source)
          return vim.trim(source):gsub("/+$", ""):gsub("%.git$", "")
        end
        if remote.code ~= 0 or normalize(remote.stdout or "") ~= normalize(spec.src) then
          error("Installed source differs from manifest: " .. plugin_name(spec)
            .. ". Close other managed Neovim instances before retrying.")
        end
      end
    end
    -- Install hooks run before loading; readers need the same dependency roots.
    for _, name in ipairs(names) do
      vim.opt.runtimepath:append(paths[name])
    end
    if paths.middleclass then
      package.path = paths.middleclass .. "/?.lua;" .. package.path
    end
    -- Packadd can download CodeSnap's native library into its plugin directory.
    -- Keep the exclusive lease until plugin scripts have finished loading.
    vim.api.nvim_clear_autocmds({ group = group, event = "PackChanged" })
    vim.g.mapleader = " "
    for _, name in ipairs(names) do
      if name == "codesnap.nvim" and not guard.writer then
        M.codesnap_available = false
        warn("CodeSnap skipped: another managed Neovim instance is running; close it and restart to enable CodeSnap.")
      elseif name == "codesnap.nvim" then
        local loaded, load_error = pcall(vim.cmd.packadd, name)
        M.codesnap_available = loaded
        if not loaded then
          warn("CodeSnap unavailable: " .. tostring(load_error))
        end
      else
        vim.cmd.packadd(name)
      end
    end
    guard.share()
    require("nvix.mason").setup(vim.g.nvix, guard.writer)
    require("nvix.lsp").setup(vim.g.nvix)
    require("nvix.editor").setup(vim.g.nvix)
  end, debug.traceback)
  vim.env.GIT_TERMINAL_PROMPT = terminal_prompt
  vim.env.GCM_INTERACTIVE = credential_interactive
  vim.api.nvim_clear_autocmds({ group = group, event = "PackChanged" })
  if not success then
    -- Preserve the lifetime lease even after partial startup: loaded plugin
    -- code must not race a later instance's updates.
    local shared, share_error = pcall(guard.share)
    if not shared then
      guard.close()
      warn(tostring(share_error))
    end
    warn("Native startup failed: " .. tostring(err))
  end
end

return M
