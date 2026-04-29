return {
  {
    "dlyongemallo/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewFocusFiles",
      "DiffviewToggleFiles",
    },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff view" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Close diff view" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Current file history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Repo history" },
      { "<leader>gm", "<cmd>DiffviewOpen --imply-local<cr>", desc = "Merge conflicts" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        merge_tool = {
          layout = "diff3_mixed",
        },
      },
      file_panel = {
        listing_style = "tree",
        win_config = {
          position = "left",
          width = 35,
        },
      },
    },
  },
  {
    "madmaxieee/unclash.nvim",
    event = "BufReadPre",
    opts = {},
  },
}
