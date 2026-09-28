return {
  "stevearc/overseer.nvim",
  event = "VeryLazy",
  opts = {
    templates = { "builtin", "npm", "yarn" },
  },
  config = function(_, opts)
    local overseer = require("overseer")
    overseer.setup(opts)

    -- jobstart sizes the pty from vim.o.columns at task start and never resizes it,
    -- so a task started in a narrow window keeps wrapping narrow.
    vim.api.nvim_create_autocmd("VimResized", {
      group = vim.api.nvim_create_augroup("overseer_pty_resize", { clear = true }),
      callback = function()
        for _, task in ipairs(overseer.list_tasks()) do
          local job_id = task:is_running() and task.strategy and task.strategy.job_id
          if job_id then
            pcall(vim.fn.jobresize, job_id, vim.o.columns - 4, vim.o.lines - 4)
          end
        end
      end,
    })
  end,
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
