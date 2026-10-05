-- The herdr side is linked to this same checkout, so :Lazy update keeps both halves current:
--   herdr plugin link ~/.local/share/nvim/lazy/vim-herdr-navigation
return {
  {
    "paulbkim-dev/vim-herdr-navigation",
    lazy = false,
    config = function(plugin)
      dofile(plugin.dir .. "/editor/nvim.lua")
    end,
  },
}
