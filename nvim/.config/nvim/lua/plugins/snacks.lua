-- LazyVim opens lazygit through Snacks, not kdheepak/lazygit.nvim, so the window is
-- styled here. The vim.g.lazygit_floating_window_* variables this replaces were read by
-- nobody.
return {
  {
    "folke/snacks.nvim",
    opts = {
      styles = {
        lazygit = {
          width = 0.9,
          height = 0.9,
          border = "rounded",
          backdrop = false,
        },
      },
    },
  },
}
