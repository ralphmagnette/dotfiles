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
    init = function()
      local function set_side_hl()
        local ok, palettes = pcall(require, "catppuccin.palettes")
        if not ok then
          return
        end
        local c = palettes.get_palette()
        local blend = require("catppuccin.utils.colors").blend
        local hl = vim.api.nvim_set_hl
        hl(0, "DiffviewSideDelLine", { bg = blend(c.red, c.base, 0.15) })
        hl(0, "DiffviewSideDelText", { bg = blend(c.red, c.base, 0.4) })
        hl(0, "DiffviewSideAddLine", { bg = blend(c.green, c.base, 0.15) })
        hl(0, "DiffviewSideAddText", { bg = blend(c.green, c.base, 0.4) })
        hl(0, "DiffviewSideFiller", { fg = c.surface1, bg = c.mantle })
      end
      set_side_hl()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("diffview_side_hl", { clear = true }),
        callback = set_side_hl,
      })
    end,
    opts = {
      enhanced_diff_hl = true,
      hooks = {
        -- Tint the old side red and the new side green, like Fork/WebStorm, instead of
        -- the same DiffChange colour on both sides.
        diff_buf_win_enter = function(_, _, ctx)
          if not ctx.layout_name:match("^diff2") then
            return
          end
          local kind = ({ a = "Del", b = "Add" })[ctx.symbol]
          if not kind then
            return
          end
          vim.opt_local.winhighlight:append({
            DiffAdd = "DiffviewSide" .. kind .. "Line",
            DiffChange = "DiffviewSide" .. kind .. "Line",
            DiffText = "DiffviewSide" .. kind .. "Text",
            DiffTextAdd = "DiffviewSide" .. kind .. "Text",
            DiffDelete = "DiffviewSideFiller",
          })
        end,
      },
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
