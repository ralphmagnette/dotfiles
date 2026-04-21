vim.opt.updatetime = 1000

vim.api.nvim_create_autocmd({ "InsertLeave", "CursorHold" }, {
  pattern = "*",
  command = "silent! write",
})
