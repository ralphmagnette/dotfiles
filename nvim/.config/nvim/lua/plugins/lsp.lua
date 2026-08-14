local angularls = require("config.angularls")

return {
  {
    "neovim/nvim-lspconfig",
    -- lang.angular resolves the tsserver Angular plugin through LazyVim.get_pkg_path, which
    -- only looks in Mason. angularls.lua provisions a version-matched server outside Mason
    -- instead, so that lookup is expected to miss and warns on every startup. Silence just
    -- that package; every other Mason path still complains when genuinely absent.
    --
    -- Wraps a LazyVim internal, so a rename upstream makes this a no-op and the warning
    -- returns -- noisy, but harmless.
    init = function()
      local lazyvim = rawget(_G, "LazyVim")
      if not lazyvim or not lazyvim.get_pkg_path then
        return
      end
      local get_pkg_path = lazyvim.get_pkg_path
      lazyvim.get_pkg_path = function(pkg, path, opts)
        if pkg == "angular-language-server" then
          opts = vim.tbl_extend("force", opts or {}, { warn = false })
        end
        return get_pkg_path(pkg, path, opts)
      end
    end,
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
    -- lang.angular points tsserver's Angular plugin at Mason's copy of
    -- @angular/language-server, which is unrelated to the version angularls itself runs --
    -- and is not installed at all. Redirect it at the workspace's own resolution so both
    -- sides agree.
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local plugins = vim.tbl_get(opts, "servers", "vtsls", "settings", "vtsls", "tsserver", "globalPlugins")
      if not plugins or #plugins == 0 then
        -- The extra populates this; empty means it merged after us and the redirect below
        -- silently had nothing to rewrite.
        vim.notify("angularls: no tsserver globalPlugins to redirect", vim.log.levels.WARN)
        return
      end

      local location, reason = angularls.tsserver_plugin_location()
      for index, plugin in ipairs(plugins) do
        if plugin.name == "@angular/language-server" then
          if location then
            plugin.location = location
          else
            -- The extra's location points into Mason, which has no Angular package, so
            -- keeping it aims tsserver at a dead path. Dropping the plugin leaves vtsls
            -- doing plain TypeScript; angularls still serves templates on its own.
            table.remove(plugins, index)
            vim.notify(
              "angularls: tsserver Angular plugin disabled -- " .. (reason or "unresolved"),
              vim.log.levels.WARN
            )
          end
          break
        end
      end
    end,
  },
}
