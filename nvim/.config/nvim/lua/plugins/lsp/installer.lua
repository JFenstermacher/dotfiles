local lsp_installer = require('nvim-lsp-installer')
local server_opts = require 'plugins.lsp.servers'
local handlers = require 'plugins.lsp.handlers'

lsp_installer.setup{
  automatic_installation = true,
  ui = {
    icons = {
      server_installed = "✓",
      server_uninstalled = "✗",
      server_pending = "⟳",
    },
  }
}

for _, server in ipairs(lsp_installer.get_installed_servers()) do
  local defaults = {
    on_attach = handlers.on_attach,
    capabilities = handlers.capabilities
  }

  local server_options = server_opts[server.name] or {}
  server_options = vim.tbl_deep_extend("force", defaults, server_options)

  vim.lsp[server].setup(server_options)
end
