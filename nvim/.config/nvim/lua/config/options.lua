-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

local opt = vim.opt

-- Better defaults
opt.number = true
opt.relativenumber = false
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.swapfile = false
opt.timeoutlen = 300

-- Drives CursorHold, which is what triggers the idle autosave and checktime in
-- config/autocmds.lua. Keep it here so there is one owner for the value.
opt.updatetime = 1000

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
opt.foldlevel = 99
opt.foldlevelstart = 99

-- Use Intelephense for PHP rather than the extra's phpactor default. The extra reads this
-- at module load, so it has to be set here (before lazy) rather than on a plugin spec.
vim.g.lazyvim_php_lsp = "intelephense"
