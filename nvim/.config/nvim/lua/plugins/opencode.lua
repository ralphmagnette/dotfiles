return {
  "sudo-tee/opencode.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        anti_conceal = { enabled = false },
        file_types = { "markdown", "opencode_output" },
      },
      ft = { "markdown", "opencode_output" },
    },
  },
  config = function()
    require("opencode").setup({})
  end,
  keys = {
    { "<leader>aa", "<cmd>Opencode<cr>", desc = "Toggle Opencode" },
    { "<leader>ae", "<cmd>Opencode open input<cr>", mode = "v", desc = "Edit selection" },
    { "<leader>ar", "<cmd>Opencode open output<cr>", desc = "Review output" },
  },
}
