local M = {
  on_attach = require 'plugins.lsp.on_attach',
  settings = {
    Lua = {
      completion = {keywordSnippet = "Disable"},
      diagnostics = {
        globals = {'vim', 'use', 'packer_plugins'},
        disable = {'lowercase-global'}
      },
      runtime = {version = 'LuaJIT', path = vim.split(package.path, ';')},
      workspace = {
        library = {
          [vim.fn.expand('$VIMRUNTIME/lua')] = true,
          [vim.fn.expand('$VIMRUTNIME/lua/vim/lsp')] = true
        }
      }
    }
  }
}

return M
