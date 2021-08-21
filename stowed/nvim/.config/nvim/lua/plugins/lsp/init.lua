local lspinstall = require 'lspinstall'
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

local function setup_servers()
  lspinstall.setup()

  local servers = lspinstall.installed_servers()
  local configs = require 'plugins.lsp.langs'

  local lspconfig = require 'lspconfig'
  for _, server in pairs(servers) do
    local config = configs[server] or {}  

    lspconfig[server].setup(config)
  end
end

setup_servers()
