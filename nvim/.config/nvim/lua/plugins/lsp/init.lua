require('plugins.lsp.lsp_installer')
require('plugins.lsp.handlers').setup()

-- Do I want any of this now?
-- local on_attach = require 'plugins.lsp.on_attach'
-- local protocol = require 'vim.lsp.protocol'

--protocol.SymbolKind = { }
-- protocol.CompletionItemKind = {
--   '', -- Text
--   '', -- Method
--   '', -- Function
--   '', -- Constructor
--   '', -- Field
--   '', -- Variable
--   '', -- Class
--   'ﰮ', -- Interface
--   '', -- Module
--   '', -- Property
--   '', -- Unit
--   '', -- Value
--   '', -- Enum
--   '', -- Keyword
--   '﬌', -- Snippet
--   '', -- Color
--   '', -- File
--   '', -- Reference
--   '', -- Folder
--   '', -- EnumMember
--   '', -- Constant
--   '', -- Struct
--   '', -- Event
--   'ﬦ', -- Operator
--   '', -- TypeParameter
-- }

-- vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
--   vim.lsp.diagnostic.on_publish_diagnostics, {
--     underline = true,
--     virtual_text = {
--       spacing = 4,
--       prefix = ''
--     }
--   }
-- )
