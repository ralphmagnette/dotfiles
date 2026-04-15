-- Add plugins to enhance LazyVim

return {
  -- Configure TypeScript LSP to ignore monorepo warnings
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tsserver = {
          init_options = {
            preferences = {
              quotePreference = "single",
              importModuleSpecifierPreference = "relative",
            },
            disableAutomaticTypeAcquisition = true,
          },
          settings = {
            typescript = {
              tsserver = {
                logVerbosity = "off",
              },
              surveys = {
                enabled = false,
              },
              enablePromptUseWorkspaceTsdk = true,
            },
          },
          on_attach = function(client, bufnr)
            -- Disable specific warnings for monorepo tsconfig conflicts
            if client.server_capabilities.diagnosticsProvider then
              vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
                vim.lsp.diagnostic.on_publish_diagnostics,
                {
                  underline = true,
                  virtual_text = true,
                  signs = true,
                  update_in_insert = false,
                  -- Filter out tsconfig warnings and schema validation errors
                  diagnostic_filter = function(diagnostic)
                    local msg = diagnostic.message
                    -- Filter monorepo and tsconfig-related warnings
                    if msg:match("tsconfig") or
                       msg:match("The file is not part of the project") or
                       msg:match("Cannot find") or
                       msg:match("is not allowed") or
                       msg:match("is not valid") or
                       msg:match("Unknown compiler option") or
                       msg:match("Property '.*' is missing in type") or
                       msg:match("Property '.*' does not exist") then
                      return false
                    end
                    return true
                  end,
                }
              )
            end
          end,
        },
      },
    },
  },

  -- Better diff view
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
  },

  -- Jump to any buffer
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

  -- Better quickfix
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = true,
  },

  -- Oil.nvim for file browser (better than netrw)
  {
    "stevearc/oil.nvim",
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
    },
    opts = {},
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
}
