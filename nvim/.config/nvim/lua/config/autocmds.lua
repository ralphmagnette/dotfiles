-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.o.autoread = true

-- Cleared on redefinition so a config reload replaces these rather than stacking a
-- second copy on every CursorHold.
local group = vim.api.nvim_create_augroup("user_autosave", { clear = true })

-- Reload externally changed files before doing anything
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  group = group,
  pattern = "*",
  command = "silent! checktime",
})

-- Auto-save on insert leave / idle, but only if buffer wasn't changed externally
vim.api.nvim_create_autocmd({ "InsertLeave", "CursorHold" }, {
  group = group,
  pattern = "*",
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].modified and vim.bo[buf].modifiable and vim.bo[buf].buftype == "" then
      -- Flags the write as involuntary so the organize-imports hook below can sit it out.
      vim.b[buf].user_autosaving = true
      vim.cmd("silent! write")
      vim.b[buf].user_autosaving = nil
    end
  end,
})

local ORGANIZE_TIMEOUT_MS = 1000

--- Organize imports synchronously.
---
--- vim.lsp.buf.code_action({ apply = true }) is async, so on BufWritePre its edit can
--- land after the file already went to disk -- leaving the buffer and the file
--- disagreeing until the next write. Driving the request/resolve/apply cycle here keeps
--- the whole thing inside the pre-write hook.
---@param bufnr integer
local function organize_imports(bufnr)
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = "vtsls" })[1]
  if not client then
    return
  end

  -- Whole-file action, so the range is irrelevant; built from the buffer rather than the
  -- current window because :wa fires this for buffers that aren't on screen.
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    range = { start = { line = 0, character = 0 }, ["end"] = { line = 0, character = 0 } },
    context = { diagnostics = {}, only = { "source.organizeImports" } },
  }

  local response = client:request_sync("textDocument/codeAction", params, ORGANIZE_TIMEOUT_MS, bufnr)
  local action = response and not response.err and (response.result or {})[1]
  if not action then
    return
  end

  -- vtsls hands back the action unresolved -- the edit only exists after a resolve.
  local edit = action.edit
  if not edit then
    local resolved = client:request_sync("codeAction/resolve", action, ORGANIZE_TIMEOUT_MS, bufnr)
    edit = resolved and not resolved.err and resolved.result and resolved.result.edit
  end

  if edit then
    vim.lsp.util.apply_workspace_edit(edit, client.offset_encoding)
  end
end

vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
  callback = function(ev)
    -- Deliberate saves only: reordering imports on a 1s idle timer moves code out from
    -- under the cursor while you are still editing.
    if vim.b[ev.buf].user_autosaving then
      return
    end
    organize_imports(ev.buf)
  end,
})
