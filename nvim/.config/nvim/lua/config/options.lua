-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

local opt = vim.opt

-- Better defaults
opt.number = true
opt.relativenumber = false
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.swapfile = false
opt.updatetime = 200
opt.timeoutlen = 300

-- Indentation
opt.expandtab = true
opt.shiftwidth = 2
opt.smartindent = true
opt.tabstop = 2
opt.softtabstop = 2

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- UI
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.termguicolors = true

-- Split behavior
opt.splitright = true
opt.splitbelow = true

-- Completion
opt.completeopt = { "menu", "menuone", "noselect" }
opt.shortmess:append("c")

-- Fold
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99

-- Quickfix
opt.hidden = true

-- Configure how diagnostics (errors, warnings) are displayed
vim.diagnostic.config({
  virtual_text = {
    spacing = 2,
    prefix = "●",
  },
  float = {
    border = "rounded",
  },
  severity_sort = true,
})

-- Show diagnostic popup when cursor is idle on a line
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.diagnostic.open_float(nil, {
      focus = false,
      border = "rounded",
    })
  end,
})

-- Faster CursorHold trigger for quicker popup
vim.o.updatetime = 250

-- LazyGit UI tweaks
vim.g.lazygit_floating_window_winblend = 0
vim.g.lazygit_floating_window_scaling_factor = 0.9
vim.g.lazygit_floating_window_border_chars = { "╭", "╮", "╰", "╯" }

-- Enable proper terminal colors (important for LazyGit UI)
vim.opt.termguicolors = true
