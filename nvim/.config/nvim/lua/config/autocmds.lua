-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.opt.updatetime = 1000
vim.o.autoread = true

-- Reload externally changed files before doing anything
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  pattern = "*",
  command = "silent! checktime",
})

-- Auto-save on insert leave / idle, but only if buffer wasn't changed externally
vim.api.nvim_create_autocmd({ "InsertLeave", "CursorHold" }, {
  pattern = "*",
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].modified and vim.bo[buf].modifiable and vim.bo[buf].buftype == "" then
      vim.cmd("silent! write")
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
  callback = function()
    vim.lsp.buf.code_action({
      context = {
        diagnostics = {},
        only = { "source.organizeImports" },
      },
      apply = true,
    })
  end,
})
