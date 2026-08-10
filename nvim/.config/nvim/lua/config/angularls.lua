--- Provisioning and crash recovery for @angular/language-server.
---
--- The server drives @angular/language-service over a private API that shifts between
--- minors (21.2 calls ensureProjectAnalyzed, which 21.1 doesn't expose), and the service
--- is always loaded from the *project's* node_modules. A single global server install
--- therefore crashes on every workspace off its own version, so keep one install per
--- Angular version under stdpath("data")/angularls and pick the matching one when the
--- client attaches.
local M = {}

local fs, fn, uv = vim.fs, vim.fn, vim.uv
local pkgman = require("config.pkgman")

local server_cache = fs.joinpath(fn.stdpath("data"), "angularls")
local resolved = {} ---@type table<string, string> root_dir -> install dir
local pending = {} ---@type table<string, fun(dir: string?)[]> version -> waiting callbacks

local function package_dir(dir)
  return fs.joinpath(dir, "node_modules/@angular/language-server")
end

local function server_bin(dir)
  return fs.joinpath(package_dir(dir), "bin/ngserver")
end

local function read_version(root, pkg)
  local ok, blob = pcall(fn.readblob, fs.joinpath(root, "node_modules/@angular", pkg, "package.json"))
  if not ok or not blob then
    return nil
  end
  local decoded = vim.json.decode(blob)
  return decoded and decoded.version
end

local function workspace_version(root)
  return read_version(root, "language-service") or read_version(root, "core")
end

local function run_install(dir, attempts, index, done)
  local attempt = attempts[index]
  if not attempt then
    return done(false)
  end

  pkgman.prepare(attempt.manager, dir)
  -- Run from the cache dir, never the project: this install is unrelated to the
  -- workspace, so it must not pick up its .npmrc or trip corepack's packageManager
  -- enforcement against a manifest it has nothing to do with.
  vim.system(
    pkgman.install_cmd(attempt.manager, dir, attempt.spec),
    { cwd = dir, text = true },
    vim.schedule_wrap(function(out)
      if out.code == 0 and uv.fs_stat(server_bin(dir)) then
        return done(true, attempt.manager)
      end
      if attempts[index + 1] then
        return run_install(dir, attempts, index + 1, done)
      end
      vim.notify(
        ("angularls: %s failed to install %s\n%s"):format(attempt.manager, attempt.spec, out.stderr or ""),
        vim.log.levels.ERROR
      )
      done(false)
    end)
  )
end

local function ensure_server(root, done)
  -- A repo that depends on @angular/language-server itself is already aligned by its
  -- lockfile; nvim-lspconfig only ever resolves ngserver off PATH, so check here.
  if uv.fs_stat(server_bin(root)) then
    return done(root)
  end

  local version = workspace_version(root)
  if not version then
    return done(nil)
  end

  -- Keyed on version alone: the cache is shared across projects, and the detected
  -- manager only decides how a missing entry gets built, not what it contains.
  local dir = fs.joinpath(server_cache, version)
  if uv.fs_stat(server_bin(dir)) then
    return done(dir)
  end

  -- Queue behind an install already in flight rather than giving up: a second Angular
  -- buffer opened during the install would otherwise never get a client, because
  -- root_dir only ever fires once per buffer.
  if pending[version] then
    table.insert(pending[version], done)
    return
  end
  pending[version] = { done }

  local managers = { pkgman.detect(root) }
  if managers[1] ~= "npm" then
    table.insert(managers, "npm")
  end

  local attempts = {}
  for _, manager in ipairs(managers) do
    if pkgman.available(manager) then
      for _, spec in ipairs({ version, "~" .. version }) do
        table.insert(attempts, { manager = manager, spec = "@angular/language-server@" .. spec })
      end
    end
  end
  if #attempts == 0 then
    pending[version] = nil
    vim.notify("angularls: no usable package manager for " .. root, vim.log.levels.WARN)
    return done(nil)
  end

  vim.notify(
    ("angularls: installing @angular/language-server@%s with %s"):format(version, attempts[1].manager),
    vim.log.levels.INFO
  )
  run_install(dir, attempts, 1, function(ok)
    local waiting = pending[version] or {}
    pending[version] = nil
    for _, callback in ipairs(waiting) do
      callback(ok and dir or nil)
    end
  end)
end

local function probe_locations(root, dir)
  local roots, seen = {}, {}
  for _, base in ipairs({ root, dir }) do
    local node_modules = fs.joinpath(base, "node_modules")
    if not seen[node_modules] and uv.fs_stat(node_modules) then
      seen[node_modules] = true
      table.insert(roots, node_modules)
    end
  end

  local ng = vim.list_slice(roots)
  for _, p in ipairs(roots) do
    table.insert(ng, fs.joinpath(p, "@angular/language-server/node_modules"))
  end

  return table.concat(roots, ","), table.concat(ng, ",")
end

-- @angular/language-service throws out of getSourceFileOrError when it is asked for a
-- component's .ngtypecheck.ts shim before tsserver finished building the program, and
-- nothing catches it, so ngserver exits and templates lose completion and diagnostics
-- until the client is started by hand. On a project the size of apps/shop (~3k files in
-- one program) that race is reliably lost by whichever file is opened first after
-- startup. Reattaching once the program is warm is enough to get a working server, so do
-- it automatically -- but budget the attempts, because a server that is actually broken
-- rather than merely racing has to report itself instead of respawning forever.
local MAX_RESTARTS = 3
local BACKOFF_MS = { 500, 2000, 5000 }
local HEALTHY_MS = 60000

local sessions = {} ---@type table<integer, { root: string, started: number, buffers: integer[] }>
local crashes = {} ---@type table<string, integer> root_dir -> consecutive crashes

local function reattach(session)
  -- vim.lsp.enable's FileType autocmd is the only thing that starts the client, so
  -- replaying it is the supported way back in. vim.lsp.start dedupes on name and
  -- root_dir, so buffers that recovered on their own are left alone.
  for _, bufnr in ipairs(session.buffers) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
      pcall(vim.api.nvim_exec_autocmds, "FileType", {
        group = "nvim.lsp.enable",
        buffer = bufnr,
        modeline = false,
      })
    end
  end
end

--- Package directory to hand tsserver as the Angular plugin location. Prefers whatever
--- the workspace itself resolves, so vtsls loads the same version angularls runs rather
--- than Mason's unrelated copy.
---
--- Resolved from cwd rather than a buffer, because tsserver plugins are configured once
--- for the whole session. Walks up to the workspace root so launching nvim inside a
--- subdirectory still finds the install.
---@return string?
function M.tsserver_plugin_location()
  local root = fs.root(uv.cwd() or ".", { "angular.json", "nx.json" })
  if not root then
    return nil
  end
  if uv.fs_stat(server_bin(root)) then
    return package_dir(root)
  end

  local version = workspace_version(root)
  if not version then
    return nil
  end
  local dir = fs.joinpath(server_cache, version)
  return uv.fs_stat(server_bin(dir)) and package_dir(dir) or nil
end

---@param bufnr integer
---@param on_dir fun(dir: string)
function M.root_dir(bufnr, on_dir)
  local root = fs.root(bufnr, { "angular.json", "nx.json" })
  if not root then
    return
  end
  ensure_server(root, function(dir)
    if not dir then
      return
    end
    resolved[root] = dir
    on_dir(root)
  end)
end

function M.cmd(dispatchers, config)
  local root = config.root_dir
  local dir = resolved[root]
  -- root_dir only calls on_dir once an install is resolved, so this should be
  -- unreachable; fail loudly rather than building a path out of nil.
  if not dir then
    error("angularls: no server install resolved for " .. tostring(root))
  end

  local ts_probe, ng_probe = probe_locations(root, dir)
  return vim.lsp.rpc.start({
    "node",
    server_bin(dir),
    "--stdio",
    "--tsProbeLocations",
    ts_probe,
    "--ngProbeLocations",
    ng_probe,
    "--angularCoreVersion",
    workspace_version(root) or "",
  }, dispatchers)
end

function M.on_attach(client, bufnr)
  local session = sessions[client.id]
  if not session then
    session = { root = client.root_dir or "", started = uv.hrtime() / 1e6, buffers = {} }
    sessions[client.id] = session
  end
  if not vim.tbl_contains(session.buffers, bufnr) then
    table.insert(session.buffers, bufnr)
  end
end

function M.on_exit(code, signal, client_id)
  local session = sessions[client_id]
  sessions[client_id] = nil

  -- SIGTERM is how :LspStop and shutdown ask politely; only an unexpected exit is a crash.
  if not session or (code == 0 and signal == 0) or signal == 15 then
    return
  end

  -- Called straight off the process handle, so nothing here may touch the API yet.
  vim.schedule(function()
    if vim.v.exiting ~= vim.NIL or vim.v.dying ~= 0 then
      return
    end

    -- A client that stayed up this long was working, so the next crash starts a fresh
    -- budget rather than inheriting one spent days ago.
    if uv.hrtime() / 1e6 - session.started >= HEALTHY_MS then
      crashes[session.root] = nil
    end

    local attempt = (crashes[session.root] or 0) + 1
    crashes[session.root] = attempt

    if attempt > MAX_RESTARTS then
      vim.notify(
        ("angularls: crashed %d times in a row, leaving it stopped\n%s"):format(MAX_RESTARTS, session.root),
        vim.log.levels.ERROR
      )
      return
    end

    vim.defer_fn(function()
      reattach(session)
    end, BACKOFF_MS[attempt] or BACKOFF_MS[#BACKOFF_MS])
  end)
end

return M
