local lspinstall = require 'lspinstall'
local on_attach = require 'plugins.lsp.on_attach'
local protocol = require 'vim.lsp.protocol'

--protocol.SymbolKind = { }
protocol.CompletionItemKind = {
  '', -- Text
  '', -- Method
  '', -- Function
  '', -- Constructor
  '', -- Field
  '', -- Variable
  '', -- Class
  'ﰮ', -- Interface
  '', -- Module
  '', -- Property
  '', -- Unit
  '', -- Value
  '', -- Enum
  '', -- Keyword
  '﬌', -- Snippet
  '', -- Color
  '', -- File
  '', -- Reference
  '', -- Folder
  '', -- EnumMember
  '', -- Constant
  '', -- Struct
  '', -- Event
  'ﬦ', -- Operator
  '', -- TypeParameter
}

vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    underline = true,
    virtual_text = {
      spacing = 4,
      prefix = ''
    }
  }
)

local function setup_servers()
  lspinstall.setup()

  local servers = lspinstall.installed_servers()
  local configs = require 'plugins.lsp.langs'

  local lspconfig = require 'lspconfig'
  for _, server in pairs(servers) do
    local config = configs[server] or { on_attach = on_attach }

    lspconfig[server].setup(config)
  end
end

setup_servers()
