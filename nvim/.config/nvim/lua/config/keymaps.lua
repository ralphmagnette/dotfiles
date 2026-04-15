-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local keymap = vim.keymap.set

-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", { desc = "Window left" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Window down" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Window up" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Move lines
keymap("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
keymap("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
keymap("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
keymap("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Move buffer left/right
keymap("n", "<leader>bl", "<cmd>BufferLineMoveNext<cr>", { desc = "Move buffer right" })
keymap("n", "<leader>bh", "<cmd>BufferLineMovePrev<cr>", { desc = "Move buffer left" })

-- Better indenting
keymap("v", "<", "<gv", { desc = "Indent left" })
keymap("v", ">", ">gv", { desc = "Indent right" })

-- Center screen on search
keymap("n", "n", "nzzzv", { desc = "Next search result (centered)" })
keymap("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })

-- Clear highlights
keymap("n", "<Esc>", ":nohlsearch<CR>", { desc = "Clear highlights" })

-- Save with Ctrl+S
keymap("n", "<C-s>", ":w<CR>", { desc = "Save file" })
keymap("i", "<C-s>", "<Esc>:w<CR>", { desc = "Save file" })

-- Quit with Ctrl+Q
keymap("n", "<C-q>", ":qa<CR>", { desc = "Quit all" })

-- Terminal keymaps
keymap("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
keymap("t", "<C-h>", "<Cmd>wincmd h<CR>", { desc = "Terminal left" })
keymap("t", "<C-j>", "<Cmd>wincmd j<CR>", { desc = "Terminal down" })
keymap("t", "<C-k>", "<Cmd>wincmd k<CR>", { desc = "Terminal up" })
keymap("t", "<C-l>", "<Cmd>wincmd l<CR>", { desc = "Terminal right" })

-- Overseer.nvim keymaps
keymap("n", "<leader>or", "<cmd>OverseerRun<cr>", { desc = "Run task" })
keymap("n", "<leader>os", "<cmd>OverseerQuickAction<cr>", { desc = "Stop task" })
keymap("n", "<leader>ot", "<cmd>OverseerToggle<cr>", { desc = "Task list" })
keymap("n", "<leader>oa", "<cmd>OverseerRun<cr>", { desc = "Run again" })

-- Error keymaps --
vim.keymap.set("n", "]e", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })
vim.keymap.set("n", "[e", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Prev diagnostic" })
keymap("n", "<leader>fd", require("telescope.builtin").diagnostics, {
  desc = "Find diagnostics",
})

-- Git workflow keymaps --
keymap("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Git diff view" })
keymap("n", "<leader>gh", "<cmd>DiffviewFileHistory<cr>", { desc = "File history" })
