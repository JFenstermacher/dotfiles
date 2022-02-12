local M = {
  on_attach = require 'plugins.lsp.on_attach',
  -- on_init = function(client)
  --   print(vim.inspect(client))
  -- end,
  before_init = function(client)
    print(vim.inspect(client))
  end,
  settings = {
    python = {
      analysis = {
        typeCheckingMode = 'off'
      }
    }
  }
}

return M
