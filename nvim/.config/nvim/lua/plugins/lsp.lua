local angularls = require("config.angularls")

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        float = { border = "rounded" },
      },
      servers = {
        angularls = {
          mason = false,
          on_attach = angularls.on_attach,
          on_exit = angularls.on_exit,
          root_dir = angularls.root_dir,
          cmd = angularls.cmd,
        },
        vtsls = {
          settings = {
            typescript = {
              preferences = {
                quoteStyle = "single",
                importModuleSpecifier = "relative",
              },
            },
            vtsls = {
              autoUseWorkspaceTsdk = true,
              experimental = {
                completion = {
                  enableServerSideFuzzyMatch = true,
                },
              },
            },
          },
          on_attach = function(client)
            client.server_capabilities.documentFormattingProvider = false
          end,
        },
        ts_ls = { enabled = false },
      },
    },
  },
  {
    -- The lang.angular extra points tsserver's Angular plugin at Mason's copy of
    -- @angular/language-server, which is unrelated to the version angularls itself runs.
    -- Redirect it at the workspace's own resolution so both sides agree.
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local location = angularls.tsserver_plugin_location()
      if not location then
        return
      end
      local plugins = vim.tbl_get(opts, "servers", "vtsls", "settings", "vtsls", "tsserver", "globalPlugins")
      for _, plugin in ipairs(plugins or {}) do
        if plugin.name == "@angular/language-server" then
          plugin.location = location
        end
      end
    end,
  },
}
