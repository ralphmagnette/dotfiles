return {
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
    },
    keys = {
      {
        "<leader>gd",
        "<cmd>DiffviewOpen<cr>",
        mode = "n",
        desc = "Git diff view",
      },
      {
        "<leader>gh",
        "<cmd>DiffviewFileHistory<cr>",
        mode = "n",
        desc = "File history",
      },
    },
  },
}
