local lsp_installer = require 'nvim-lsp-installer'
local handlers = require('plugins.lsp.handlers')

lsp_installer.on_server_ready(function(server)
  local server_opts = require 'plugins.lsp.langs'

  local defaults = {
    on_attach = handlers.on_attach,
    capabilities = handlers.capabilities
  }

  local server_options = server_opts[server.name] or {}
  server_options = vim.tbl_deep_extend("force", defaults, server_options)

  server:setup(server_options)
end)
