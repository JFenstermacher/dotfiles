local M = {
  on_attach = require 'plugins.lsp.on_attach',
  settings = {
    python = {
      analysis = {
        typeCheckingMode = 'off'
      }
    }
  }
}

return M
