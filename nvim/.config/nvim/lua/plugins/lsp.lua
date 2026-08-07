local fs, fn, uv = vim.fs, vim.fn, vim.uv
local pkgman = require("config.pkgman")

-- @angular/language-server drives @angular/language-service over a private API that
-- shifts between minors (21.2 calls ensureProjectAnalyzed, which 21.1 doesn't expose),
-- and the service is always loaded from the *project's* node_modules. A single global
-- server install therefore crashes on every workspace off its own version, so instead
-- keep one install per Angular version under stdpath("data")/angularls and pick the
-- matching one when the client attaches.
local server_cache = fs.joinpath(fn.stdpath("data"), "angularls")
local resolved = {} ---@type table<string, string> root_dir -> install dir
local installing = {} ---@type table<string, boolean> version -> in flight

local function server_bin(dir)
  return fs.joinpath(dir, "node_modules/@angular/language-server/bin/ngserver")
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
  if installing[version] then
    return done(nil)
  end

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
    vim.notify("angularls: no usable package manager for " .. root, vim.log.levels.WARN)
    return done(nil)
  end

  installing[version] = true
  vim.notify(
    ("angularls: installing @angular/language-server@%s with %s"):format(version, attempts[1].manager),
    vim.log.levels.INFO
  )
  run_install(dir, attempts, 1, function(ok)
    installing[version] = nil
    done(ok and dir or nil)
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

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        angularls = {
          mason = false,
          root_dir = function(bufnr, on_dir)
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
          end,
          cmd = function(dispatchers, config)
            local root = config.root_dir
            local dir = resolved[root]
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
          end,
        },
        vtsls = {
          settings = {
            typescript = {
              preferences = {
                quoteStyle = "single",
                importModuleSpecifier = "relative",
              },
            },
            vtsls = {
              autoUseWorkspaceTsdk = true,
              experimental = {
                completion = {
                  enableServerSideFuzzyMatch = true,
                },
              },
            },
          },
          on_attach = function(client)
            client.server_capabilities.documentFormattingProvider = false
          end,
        },
        ts_ls = { enabled = false },
        phpactor = { enabled = false },
      },
    },
  },
}
