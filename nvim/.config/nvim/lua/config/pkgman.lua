--- Per-project package manager detection.
---
--- Corepack enforces package.json's "packageManager" field, so guessing wrong doesn't
--- merely pick a slower tool: pnpm and yarn refuse to run at all. That field is the
--- authority when present, with the nearest lockfile as the fallback.
local M = {}

local fs, fn, uv = vim.fs, vim.fn, vim.uv

-- Ordered by priority within a single directory, since a repo mid-migration can carry
-- more than one lockfile.
local LOCKFILES = {
  { file = "pnpm-lock.yaml", manager = "pnpm" },
  { file = "bun.lock", manager = "bun" },
  { file = "bun.lockb", manager = "bun" },
  { file = "yarn.lock", manager = "yarn" },
  { file = "package-lock.json", manager = "npm" },
}

---@param dir string
---@return string? manager
local function declared_in(dir)
  local ok, blob = pcall(fn.readblob, fs.joinpath(dir, "package.json"))
  if not ok or not blob then
    return nil
  end
  local decoded = vim.json.decode(blob)
  local declared = decoded and decoded.packageManager
  return type(declared) == "string" and declared:match("^(%a+)") or nil
end

--- Walks up explicitly rather than using vim.fs.root, which resolves a flat marker
--- list by marker order across the whole tree -- an ancestor's pnpm-lock.yaml would
--- outrank a nested project's own package-lock.json. Proximity has to win first.
---@param root string
---@return string manager
function M.detect(root)
  local dirs = { root }
  for parent in fs.parents(root) do
    table.insert(dirs, parent)
  end

  for _, dir in ipairs(dirs) do
    local declared = declared_in(dir)
    if declared then
      return declared
    end
    for _, lock in ipairs(LOCKFILES) do
      if uv.fs_stat(fs.joinpath(dir, lock.file)) then
        return lock.manager
      end
    end
  end

  return "npm"
end

---@param manager string
---@return boolean
function M.available(manager)
  return fn.executable(manager) == 1
end

--- Seed an isolated install directory. Its own manifest keeps corepack and npm's
--- prefix resolution from walking up into an unrelated project.
---@param manager string
---@param dir string
function M.prepare(manager, dir)
  fn.mkdir(dir, "p")

  local manifest = fs.joinpath(dir, "package.json")
  if not uv.fs_stat(manifest) then
    fn.writefile({ '{ "name": "nvim-package-cache", "private": true }' }, manifest)
  end

  if manager == "yarn" then
    -- Berry defaults to PnP, which leaves no node_modules tree to probe.
    local rc = fs.joinpath(dir, ".yarnrc.yml")
    if not uv.fs_stat(rc) then
      fn.writefile({ "nodeLinker: node-modules" }, rc)
    end
  end
end

--- Install `spec` into `dir`. Callers must run this with cwd set to `dir`.
--- Every manager is asked for a hoisted node_modules so the layout stays probeable.
---@param manager string
---@param dir string
---@param spec string
---@return string[]
function M.install_cmd(manager, dir, spec)
  if manager == "pnpm" then
    return { "pnpm", "add", "--dir", dir, "--config.node-linker=hoisted", "--lockfile=false", spec }
  elseif manager == "yarn" then
    return { "yarn", "add", spec }
  elseif manager == "bun" then
    return { "bun", "add", spec }
  end
  return { "npm", "install", "--prefix", dir, "--no-audit", "--no-fund", "--no-package-lock", spec }
end

return M
