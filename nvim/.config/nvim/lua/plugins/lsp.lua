return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ts_ls = {
          init_options = {
            preferences = {
              quotePreference = "single",
              importModuleSpecifierPreference = "relative",
            },
            disableAutomaticTypeAcquisition = true,
          },
          settings = {
            typescript = {
              enablePromptUseWorkspaceTsdk = true,
            },
            completions = {
              completeFunctionCalls = true,
            },
          },
          on_attach = function(client)
            -- Optional: disable formatting if using prettier
            client.server_capabilities.documentFormattingProvider = false
          end,
        },
      },
    },
  },
}
