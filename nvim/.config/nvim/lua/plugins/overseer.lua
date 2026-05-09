return {
  "stevearc/overseer.nvim",
  event = "VeryLazy",
  opts = {
    strategy = "toggleterm",
    templates = { "builtin", "npm", "yarn" },
  },
  keys = {
    { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Run task" },
    { "<leader>ot", "<cmd>OverseerToggle<cr>", desc = "Task list" },
    {
      "<leader>os",
      function()
        local overseer = require("overseer")
        for _, task in ipairs(overseer.list_tasks()) do
          if task:is_running() then
            task:stop()
          end
        end
      end,
      desc = "Stop tasks",
    },
  },
}
