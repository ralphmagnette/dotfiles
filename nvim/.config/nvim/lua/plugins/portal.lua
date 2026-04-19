return {
  {
    "cbochs/portal.nvim",
    dependencies = {
      "ThePrimeagen/harpoon",
    },
    keys = {
      { "<leader>po", "<cmd>Portal jumplist backward<cr>", desc = "Portal: Jump back" },
      { "<leader>pi", "<cmd>Portal jumplist forward<cr>", desc = "Portal: Jump forward" },
    },
  },
}
