local M = {}

function M.config()
  local lspconfig = require('lspconfig')
  local saga = require('lspsaga')
  local lspkind = require('lspkind')
  local lspinstall = require('lspinstall')
  local bind_buf_maps = require('configs.utils').bind_buf_maps
  local lsp = vim.lsp

  local kind_symbols = {
    Text = '',
    Method = 'Ƒ',
    Function = 'ƒ',
    Constructor = '',
    Variable = '',
    Class = '',
    Interface = 'ﰮ',
    Module = '',
    Property = '',
    Unit = '',
    Value = '',
    Enum = '了',
    Keyword = '',
    Snippet = '﬌',
    Color = '',
    File = '',
    Folder = '',
    EnumMember = '',
    Constant = '',
    Struct = ''
  }

  local sign_define = vim.fn.sign_define
  sign_define('LspDiagnosticsSignError', {text = '', numhl = 'RedSign'})
  sign_define('LspDiagnosticsSignWarning', {text = '', numhl = 'YellowSign'})
  sign_define('LspDiagnosticsSignInformation', {text = '', numhl = 'WhiteSign'})
  sign_define('LspDiagnosticsSignHint', {text = '', numhl = 'BlueSign'})

  lspkind.init {symbol_map = kind_symbols}
  lsp.handlers['textDocument/publishDiagnostics'] = lsp.with(lsp.diagnostic.on_publish_diagnostics, {
    virtual_text = false,
    signs = true,
    update_in_insert = false,
    underline = true
  })
  saga.init_lsp_saga {use_saga_diagnostic_sign = false}
  local keymap_opts = {noremap = true, silent = true}
  local function on_attach(client)
    local buf_mappings = {
      {0, 'n', ']e', ':Lspsaga diagnostic_jump_next<CR>', keymap_opts},
      {0, 'n', '[e', ':Lspsaga diagnostic_jump_previous<CR>', keymap_opts},
      {0, 'n', 'K', ':Lspsaga hover_doc<CR>', keymap_opts},
      {0, 'n', 'ga', ':Lspsaga code_action<CR>', keymap_opts},
      {0, 'v', 'ga', ':Lspsaga range_code_action<CR>', keymap_opts},
      {0, 'n', 'gd', ':Lspsaga preview_definition<CR>', keymap_opts},
      {0, 'n', 'gD', ':lua vim.lsp.buf.implementation()<CR>', keymap_opts},
      {0, 'n', 'gs', ':Lspsaga signature_help<CR>', keymap_opts},
      {0, 'n', 'gr', ':Lspsaga rename<CR>', keymap_opts},
      {0, 'n', 'gh', ':Lspsaga lsp_finder<CR>', keymap_opts},
      {0, 'n', 'gt', ':lua vim.lsp.buf.type_definition()<CR>', keymap_opts},
      {0, 'n', '<Leader>ce', ':Lspsaga show_line_diagnostics<CR>', keymap_opts}
    }

    bind_buf_maps(buf_mappings)

    if client.resolved_capabilities.document_formatting then
      bind_buf_maps({
        {0, 'n', '<Leader>lf', ':lua vim.lsp.buf.formatting()<CR>', keymap_opts}
      })
    end
  end

  lspinstall.setup()

  local servers = lspinstall.installed_servers()

  for _, server in pairs(servers) do
    lspconfig[server].setup{ on_attach = on_attach }
  end
end

return M
